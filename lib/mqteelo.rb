require "mqteelo/utils"

module MQTeelo
  class Server
    include Utils

    def initialize app
      @app = app
    end

    def handle io
      byte = io.readbyte
      flags = byte & 0xF
      type = byte >> 4
      size = read_varint(io)

      _handle io, type, flags, size
    end

    private

    def handle_connect io, flags, len
      p io.read 6   # protocol name
      p io.readbyte # protocol version

      conn_flags = io.readbyte # connect flags
      if (conn_flags & (1 << 5)) > 0
        p "will retain"
      end
      qos = conn_flags & 0b11000
      p QOS: qos
      if (conn_flags & (1 << 2)) > 0
        p "will flag"
      end

      if (conn_flags & (1 << 1)) > 0
        p "clean start"
      end

      p read_2byte_int(io) # keep alive

      p connect_properties io, read_varint(io)

      client_id = read_utf8_string io
      p client_id

      if (conn_flags & (1 << 2)) > 0
        raise NotImplementedError, "read will"
      end

      if (conn_flags & (1 << 7)) > 0 # username
        p read_utf8_string io
      end
      if (conn_flags & (1 << 6)) > 0 # password
        p read_utf8_string io
      end
    end
  end
end

require "mqteelo_gen"
