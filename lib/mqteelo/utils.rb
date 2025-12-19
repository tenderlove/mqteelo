# frozen_string_literal: true

module MQTeelo
  module Utils
    def encoded_varint_len int
      return 1 if int < 0x80
      return 2 if int < 0x4000
      return 3 if int < 0x200000
      4
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

    def encode_utf8_string str, buffer
      [str.bytesize, str].pack("na*", buffer:)
    end
    alias :encode_binary_string :encode_utf8_string

    def encode_varint value, io
      while true
        enc_byte = value % 0x80
        value /= 0x80
        enc_byte |= 0x80 if value > 0
        io.putc(enc_byte & 0xFF)
        break unless value > 0
      end
    end

    def read_utf8_string buffer, offset
      len = buffer.unpack1("n", offset:)
      buffer.byteslice(offset + 2, len).force_encoding('UTF-8')
    end

    def read_binary_string buffer, offset
      len = buffer.unpack1("n", offset:)
      buffer.byteslice(offset + 2, len)
    end
  end
end
