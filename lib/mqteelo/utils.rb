module MQTeelo
  module Utils
    def read_varint io
      value = 0
      mult = 1
      while true
        byte = io.readbyte
        value += (byte & 0x7F) * mult
        break if (byte & 0x80).zero?
        mult *= 128
      end
      value
    end

    def read_2byte_int io
      (io.readbyte << 8) | io.readbyte
    end

    def read_utf8_string io
      io.read(io.readbyte << 8 | io.readbyte).force_encoding('UTF-8')
    end
  end
end
