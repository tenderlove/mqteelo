require "socket"
require "mqteelo"
require "securerandom"
require "stringio"

server = TCPServer.new("127.0.0.1", 1883)

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

  def readbyte
    # read packet
    x = if @buffer.string.empty?
      byte = @io.readbyte
      @buffer.putc byte
      len = read_varint(@io)
      encode_varint2(len, @buffer)
      str = @io.read len
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
    conn.receive self, io
  end
end

def handle_request(fd, app)
  request_ractor = Ractor.new(fd, app) do |fd, app|
    s = IO.for_fd(fd)
    s = PacketSnoop.new(s)
    conn = MQTeelo::Connection.new
    begin
    conn.receive app, s
    rescue
      p s
      raise
    end
  end
end

app = App.new.freeze
accept_ractor = Ractor.new(server, app) do |server, app|
  while sockfd = server.sysaccept
    handle_request(sockfd, app)
  end
end.join
