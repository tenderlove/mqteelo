require "nokogiri"
require "net/http"
require "uri"
require "fileutils"
require "erb"

cache_dir = ENV["XDG_CACHE_HOME"] || File.join(ENV["HOME"], ".cache", "mqttlo")
FileUtils.mkdir_p cache_dir
cache_file = File.join(cache_dir, "mqtt.dump")

uri = URI.parse("https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html")

if File.exist?(cache_file)
  etag, response_body = Marshal.load(File.binread(cache_file))
  raise unless response_body
end

if etag
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
  end
else
  # no cache
  response = Net::HTTP.get_response(uri)
  etag = response["ETag"]
  File.binwrite(cache_file, Marshal.dump([etag, response.body]))
  etag, response_body = Marshal.load(File.binread(cache_file))
end

doc = Nokogiri::HTML.parse response_body

PacketType = Struct.new(:name, :value, :description, :flags)
Property = Struct.new(:ident, :name, :type, :packet)
Reason = Struct.new(:name, :value, :description)

def packet_types doc
  node = doc.css("a[name='_Table_2.1_-']").first.parent
  while node.name != "table"
    node = node.next_sibling
  end
  node.css("tr").map { |tr|
    tr.css("td").map { |x| x.text.strip }
  }.select { |name, | name =~ /^[A-Z]*$/ }.map { |name, value, _, desc|
    PacketType.new(name, value.to_i, desc, 0)
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
    Property.new(dec.to_i, name, type, packet)
  }
end

def reasons doc
  node = doc.css("a[name='ConnectReasonCode']").first.parent
  while node.name != "table"
    node = node.next_sibling
  end
  node.css("tr").map { |tr|
    tr.css("td").map { |x| x.text.strip }
  }.select { |dec, | dec =~ /^[0-9]*$/ }.map { |dec, _, name, desc|
    Reason.new(name, dec.to_i, desc)
  }
end

types = packet_types doc
props = properties doc
rs = reasons(doc)

template = ERB.new(DATA.read)
types.each do |type|
  p type
end

__END__

def handle_packet id, flags
end
