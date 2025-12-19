require "mqteelo"
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

  def closed?
    @io.closed?
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
