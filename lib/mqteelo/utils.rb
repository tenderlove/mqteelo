# frozen_string_literal: true

module MQTeelo
  module Utils
    def encoded_varint_len int
      return 1 if int < 0x80
      return 2 if int < 0x4000
      return 3 if int < 0x200000
      4
    end

    def encoded_utf8_len str
      str.bytesize + 2
    end

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

    def encode_2byte_int int, buffer
      [int].pack("n", buffer:)
    end

    def encode_utf8_string str, buffer
      encode_2byte_int(str.bytesize, buffer)
      buffer << str
    end
    alias :encode_binary_string :encode_utf8_string

    def encode_varint value, out
      while true
        enc_byte = value % 0x80
        value /= 0x80
        enc_byte |= 0x80 if value > 0
        out << (enc_byte & 0xFF).chr
        break unless value > 0
      end
    end

    def encode_varint2 value, out
      while true
        enc_byte = value % 0x80
        value /= 0x80
        enc_byte |= 0x80 if value > 0
        out.putc(enc_byte & 0xFF)
        break unless value > 0
      end
    end

    def read_2byte_int io
      (io.readbyte << 8) | io.readbyte
    end

    def read_utf8_string io
      io.read(io.readbyte << 8 | io.readbyte).force_encoding('UTF-8')
    end

    def read_binary_string io
      io.read(io.readbyte << 8 | io.readbyte)
    end
  end
end
