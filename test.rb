require "socket"
require "mqteelo"
require "securerandom"
require "stringio"

class PacketSnoop
  include MQTeelo::Utils

  def initialize io
    @io = io
    @buffer = StringIO.new "".b
    @packets = []
  end

  def putc ...
    @io.putc(...)
  end

  def write ...
    @io.write(...)
  end

  def read size
    if size == 0
      return ""
    end

    raise "fixme" if @buffer.string.empty?
    x = @buffer.read size
    if @buffer.eof?
      @buffer.string.clear
      @buffer.rewind
    end
    x
  end

  def flush
    @buffer.flush
  end

  def close
    @io.close
  end

  def inspect
    @buffer.string.bytes.map { |x| sprintf("%02x", x) }.join(" ") + "\n" +
      ("   " * @buffer.pos) + "^\n" + super
  end

  def readbyte
    # read packet
    x = if @buffer.string.empty?
      byte = @io.readbyte
      p ID: byte
      @buffer.putc byte
      len = read_varint(@io)
      p len: len
      encode_varint(len, @buffer)
      str = @io.read len
      p str
      @buffer << str
      @packets << @buffer.string.dup
      @buffer.rewind
      @buffer.readbyte
    else
      @buffer.readbyte
    end

    if @buffer.eof?
      @buffer.string.clear
      @buffer.rewind
    end
    x
  end

  def pos
    @io.pos
  end
end

class App
  include MQTeelo

  def on_connect conn, io, **kw
    puts "hi"
    conn.send_connack io, session_present: false,
                          reason: Reasons::SUCCESS,
                          properties: [
                            [34, 10],
                            [18, SecureRandom.uuid],
                            [33, 10]
                          ]
  end

  def on_publish conn, io, dup:, qos:, retain:, topic:, packet_id:, properties:, payload:
    p topic => payload
  end

  def on_disconnect conn, io, reason:, properties:
    io.close
  end

  def on_subscribe conn, io, packet_id:, properties:, filters:
    p packet_id
    p filters
  end
end

def handle_request(fd, app)
  request_ractor = Ractor.new(fd, app) do |fd, app|
    io = IO.for_fd(fd)
    s = PacketSnoop.new(io)
    #s = io
    conn = MQTeelo::Connection.new
    begin
      while !io.closed?
        conn.receive app, s
      end
    rescue EOFError
      io.close
      puts "done"
    rescue
      p s
      raise
    rescue NotImplementedError
      p s
      raise
    end
  end
end

server = TCPServer.new("127.0.0.1", 1883)

app = App.new.freeze
accept_ractor = Ractor.new(server, app) do |server, app|
  while sockfd = server.sysaccept
    handle_request(sockfd, app)
  end
end.join
