require "nokogiri"
require "net/http"
require "uri"
require "fileutils"
require "erb"

class ReasonTemplate
TEMPLATE = ERB.new(<<-eot, trim_mode: '-')
  module Reasons
<%- reasons.each do |reason| -%>
    <%= reason.name.upcase.sub(/-/, '').tr(' ', '_') %> = <%= sprintf("%#04x", reason.value) %>
<%- end -%>
  end
eot
  def self.result reasons
    TEMPLATE.result binding
  end
end

class Dispatch
TEMPLATE = ERB.new(<<-eot, trim_mode: '-')
  def handle io, id, flags
  <%- types.each_with_index do |type, i| -%>
    <%= i == 0 ? "if" : "elseif" %> id == <%= sprintf("%#04x", type.value) %>
    <%- if type.flags -%>
      raise "wrong flags" unless flags == <%= sprintf("%#04x", type.flags) %>
    <%- end -%>
      handle_<%= type.name.downcase %>(io, flags)
  <%- end -%>
    else
      raise "unknown id \#{id}"
    end
  end
eot
  def self.result types
    TEMPLATE.result binding
  end
end

class PropertyTemplate
  LUT = {
    "Byte" => "io.getbyte",
    "Two Byte Integer" => "io.getbyte << 8 | io.getbyte",
    "Four Byte Integer" => "io.getbyte << 24 | io.getbyte << 16 | io.getbyte << 8 | io.getbyte",
    "UTF-8 Encoded String" => "io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')",
    "UTF-8 String Pair" => "[io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8'), io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')]",
    "Binary Data" => "io.read(io.getbyte << 8 | io.getbyte)",
    "Variable Byte Integer" => "read_varint(io)",
  }
  TEMPLATE = ERB.new(<<-eot, trim_mode: '-')
  <%- props.each do |type, values| -%>
  def <%= type.downcase.gsub(/ /, '_') %><%= type =~ /properties/i ? "" : "_properties" %> io, id
    <%- values.each_with_index do |val, i| -%>
    <%= i == 0 ? "if" : "elseif" %> id == <%= sprintf("%#04x", val.ident) %> # <%= val.name %>
      <%= LUT.fetch(val.type) %>
    <%- end -%>
    else
      raise "wrong property \#{id}"
    end
  end

<%- end -%>
eot

  def self.result props
    TEMPLATE.result binding
  end
end

cache_dir = ENV["XDG_CACHE_HOME"] || File.join(ENV["HOME"], ".cache", "mqttlo")
FileUtils.mkdir_p cache_dir
cache_file = File.join(cache_dir, "mqtt.dump")

uri = URI.parse("https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html")

if File.exist?(cache_file)
  etag, response_body = Marshal.load(File.binread(cache_file))
  raise unless response_body
end

if etag
  stat = File.stat(cache_file)
  if (Time.now - stat.mtime) > (2 * 365 * 24 * 60 * 60)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Get.new(uri.request_uri)
    req["If-None-Match"] = etag
    response = http.request(req)

    if response.code != "304"
      # update cache
      etag = response["ETag"]
      File.binwrite(cache_file, Marshal.dump([etag, response.body]))
      etag, response_body = Marshal.load(File.binread(cache_file))
    else
      File.utime(stat.atime, Time.now, cache_file)
    end
  end
else
  # no cache
  response = Net::HTTP.get_response(uri)
  etag = response["ETag"]
  File.binwrite(cache_file, Marshal.dump([etag, response.body]))
  etag, response_body = Marshal.load(File.binread(cache_file))
end

DOC = Nokogiri::HTML.parse response_body

PacketType = Struct.new(:name, :value, :description, :flags)
Property = Struct.new(:ident, :name, :type, :packets)
Reason = Struct.new(:name, :value, :description)

def packet_types doc
  fbs = flag_bits(doc).to_h

  node = doc.css("a[name='_Table_2.1_-']").first.parent
  while node.name != "table"
    node = node.next_sibling
  end
  node.css("tr").map { |tr|
    tr.css("td").map { |x| x.text.strip }
  }.select { |name, | name =~ /^[A-Z]*$/ }.map { |name, value, _, desc|
    PacketType.new(name, value.to_i, desc, fbs[name])
  }
end

def properties doc
  node = doc.css("a[name='_Toc464547805']").first.parent
  while node.name != "table"
    node = node.next_sibling
  end
  node.css("tr").map { |tr|
    tr.css("td").map { |x| x.text.strip }
  }.select { |dec, | dec =~ /^[0-9]*$/ }.map { |dec, _, name, type, packet|
    Property.new(dec.to_i, name, type, packet.split(",").map(&:strip))
  }
end

def reasons doc
  node = doc.css("a[name='_Ref486836950']").first.parent
  while node.name != "table"
    node = node.next_sibling
  end
  node.css("tr").map { |tr|
    tr.css("td").map { |x| x.text.strip }
  }.select { |dec, | dec =~ /^[0-9]*$/ }.map { |dec, _, name, desc|
    Reason.new(name, dec.to_i, desc)
  }
end

def flag_bits doc
  node = doc.css("a[name='_Table_2.2_-']").first.parent
  while node.name != "table"
    node = node.next_sibling
  end
  node.css("tr").map { |tr|
    tr.css("td").map { |x| x.text.strip }
  }.select { |dec, *rest|
    dec =~ /^[A-Z]*$/ && rest.last =~ /^[01]$/
  }.map { |type, _, bit3, bit2, bit1, bit0|
    [type, bit3.to_i << 3 | bit2.to_i << 2 | bit1.to_i << 1 | bit0.to_i]
  }
end
