require "socket"
require "mqteelo"
require "stringio"
require_relative "packet_snoop"

class App
  def initialize
    @packet_id = 0
  end

  def on_connack conn, io, session_present:, reason:, properties:
    p [session_present, reason, properties]
    @packet_id += 1
    conn.send_subscribe io, packet_id: @packet_id, properties: [], filters: [["test", 0]]
  end

  def on_suback conn, io, packet_id:, properties:, payload:
    puts "Got subscription: #{packet_id}"
  end

  def on_publish conn, io, dup:, qos:, retain:, packet_id:, topic:, properties:, payload:
    p({ packet_id:, topic:, payload: })
  end

  def on_disconnect conn, io, reason:, properties:
    if reason
      p "DISCONNECT: #{MQTeelo::Reasons.to_string(reason)}"
    end
    io.close
  end
end

io = TCPSocket.open("test.mosquitto.org", 1883)
#io = PacketSnoop.new io
conn = MQTeelo::Connection.new
app = App.new
conn.send_connect io

loop do
  begin
    conn.receive app, io
  rescue NoMethodError
    p io
    raise
  end

  break if io.closed?
end
