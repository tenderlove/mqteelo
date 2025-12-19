require "nokogiri"
require "net/http"
require "uri"
require "fileutils"
require "erb"

class PacketTemplate
TEMPLATE = ERB.new(<<-eot, trim_mode: '-')
<%- types.each do |type| -%>
<%= type.name %> = (<%= sprintf("%#04x", type.value) %> << 4)<%= type.flags && type.flags > 0 ? sprintf(" | %#04x", type.flags) : "" %>
<%- end -%>
eot

  def self.result types, indent:
    TEMPLATE.result(binding).lines.map { |line| (" " * indent) + line }.map(&:rstrip).join("\n")
  end
end

class PropertyConstants
TEMPLATE = ERB.new(<<-eot, trim_mode: '-')
<%- props.each do |property| -%>
<%= property.name.gsub(/ /, '_').upcase %> = <%= sprintf("%#04x", property.ident) %>
<%- end -%>
eot
  def self.result props, indent:
    TEMPLATE.result(binding).lines.map { |line| (" " * indent) + line }.map(&:rstrip).join("\n")
  end
end

class EncodeProperty
  BYTE = "out << value"

  TWOBYTE = <<-eot
[value].pack("n", buffer: out)
  eot

  FOURBYTE = <<-eot
[value].pack("N", buffer: out)
  eot

  STRING = <<-eot
[value.bytesize, value].pack("na*", buffer: out)
  eot

  STRING_PAIR = <<-eot
[value[0].bytesize, value[0], value[1].bytesize, value[1]].pack("na*na*", buffer: out)
  eot

  BINARY = STRING

  VARINT = <<-eot
[value].pack("R", buffer: out)
  eot

  LUT = {
    "Byte" => BYTE,
    "Two Byte Integer" => TWOBYTE,
    "Four Byte Integer" => FOURBYTE,
    "UTF-8 Encoded String" => STRING,
    "UTF-8 String Pair" => STRING_PAIR,
    "Binary Data" => BINARY,
    "Variable Byte Integer" => VARINT,
  }
  TEMPLATE = ERB.new(<<-eot, trim_mode: '-')
def encode_property id, value, out
<%- props.each_with_index do |property, i| -%>
  <%= i == 0 ? "if" : "elsif" %> id == <%= sprintf("%#04x", property.ident) %>
<%= LUT[property.type].lines.map { |l| "    " + l }.join %>
<%- end -%>
  else
  end
end
eot
  def self.result props, indent:
    TEMPLATE.result(binding).lines.map { |line| (" " * indent) + line }.map(&:rstrip).join("\n")
  end
end

class ReasonTemplate
TEMPLATE = ERB.new(<<-eot, trim_mode: '-')
<%- reasons.each do |reason| -%>
<%= reason.name.upcase.sub(/-/, '').tr(' ', '_') %> = <%= sprintf("%#04x", reason.value) %>
<%- end -%>

LIST = []
<%- reasons.each do |reason| -%>
LIST[<%= sprintf("%#04x", reason.value) %>] = <%= reason.name.dump %>
<%- end -%>
LIST.freeze
def self.to_string id
  LIST[id]
end
eot
  def self.result reasons, indent:
    TEMPLATE.result(binding).lines.map { |line| (" " * indent) + line }.map(&:rstrip).join("\n")
  end
end

class Dispatch
TEMPLATE = ERB.new(<<-eot, trim_mode: '-')
def _handle app, io, id, flags, len
<%- types.each_with_index do |type, i| -%>
  <%= i == 0 ? "if" : "elsif" %> id == <%= sprintf("%#04x", type.value) %>
  <%- if type.flags -%>
    raise "wrong flags" unless flags == <%= sprintf("%#04x", type.flags) %>
  <%- end -%>
    handle_<%= type.name.downcase %>(app, io, flags, len)
<%- end -%>
  else
    raise "unknown id \#{id}"
  end
end
eot
  def self.result types, indent:
    TEMPLATE.result(binding).lines.map { |line| (" " * indent) + line }.map(&:rstrip).join("\n")
  end
end

class PropertyTemplate
  READBYTE = ERB.new(<<-eot, trim_mode: '-')
val = buffer.getbyte(read + offset)
read += 1
  eot

  TWOBYTE = ERB.new(<<-eot, trim_mode: '-')
val = buffer.unpack1("n", offset: read + offset)
read += 2
  eot

  FOURBYTE = ERB.new(<<-eot, trim_mode: '-')
val = buffer.unpack1("N", offset: read + offset)
read += 4
  eot

  STRING = ERB.new(<<-eot, trim_mode: '-')
size = buffer.unpack1("n", offset: read + offset)
read += 2
val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
read += size
  eot

  STRING_PAIR = ERB.new(<<-eot, trim_mode: '-')
size = buffer.unpack1("n", offset: read + offset)
read += 2
val1 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
read += size

size = buffer.unpack1("n", offset: read + offset)
read += 2
val2 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
read += size

val = [val1, val2]
  eot

  BINARY = ERB.new(<<-eot, trim_mode: '-')
size = buffer.unpack1("n", offset: read + offset)
read += 2
val = size.positive? ? buffer.byteslice(offset + read, size) : "".b
read += size
  eot

  VARINT = ERB.new(<<-eot, trim_mode: '-')
val = buffer.unpack1("R", offset: read + offset)
read += encoded_varint_len(val)
  eot

  LUT = {
    "Byte" => READBYTE,
    "Two Byte Integer" => TWOBYTE,
    "Four Byte Integer" => FOURBYTE,
    "UTF-8 Encoded String" => STRING,
    "UTF-8 String Pair" => STRING_PAIR,
    "Binary Data" => BINARY,
    "Variable Byte Integer" => VARINT,
  }
  TEMPLATE = ERB.new(<<-eot, trim_mode: '-')
NONE = [].freeze
  <%- props.each do |type, values| -%>

def <%= type.downcase.gsub(/ /, '_') %><%= type =~ /properties/i ? "" : "_properties" %> buffer, offset, len
  return NONE unless len.positive?

  read = 0
  properties = []
  while read < len
    id = buffer.getbyte(read + offset)
    read += 1
    <%- values.each_with_index do |val, i| -%>
    <%= i == 0 ? "if" : "elsif" %> id == <%= sprintf("%#04x", val.ident) %> # <%= val.name %>
<%= LUT.fetch(val.type).result.lines.map { "        " + _1 }.join %>
    <%- end -%>
    else
      raise "wrong property \#{sprintf("%#04x", id)}"
    end
    properties << [id, val]
  end
  properties
end

<%- end -%>
eot

  def self.result props, indent:
    TEMPLATE.result(binding).lines.map { |line| (" " * indent) + line }.map(&:rstrip).join("\n")
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
