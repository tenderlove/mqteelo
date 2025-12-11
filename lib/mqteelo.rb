require "mqteelo/utils"

module MQTeelo
  class Connection
    include Utils

    attr_reader :io

    def initialize io, app
      @io = io
      @app = app
    end

    def receive
      byte = io.readbyte
      flags = byte & 0xF
      type = byte >> 4
      size = read_varint(io)

      _handle io, type, flags, size
    end

    def send_connect version: 5,
                     will_retain: false,
                     qos: 0,
                     clean_start: true,
                     keep_alive: 60,
                     connect_properties: [[ Properties::RECEIVE_MAXIMUM, 20 ]],
                     will_properties: [],
                     will_topic: nil,
                     will_payload: nil,
                     username: nil,
                     password: nil

      conn_flags = qos
      conn_flags |= 1 << 1 if clean_start
      conn_flags |= 1 << 2 if will_topic
      conn_flags |= 1 << 5 if will_retain
      conn_flags |= 1 << 6 if password
      conn_flags |= 1 << 7 if username

      packet = "\x00\x04MQTT".b +
        [ version, conn_flags ].pack("CC") +
        encode_2byte_int(keep_alive) +
        encode_connect_properties(connect_properties)

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
        p "will flag"
        will_properties = will_properties io, read_varint(io)
        will_topic = read_utf8_string io
        will_payload = read_binary_string io
      end

      if (conn_flags & (1 << 7)) > 0 # username
        username = read_utf8_string io
      end
      if (conn_flags & (1 << 6)) > 0 # password
        password = read_utf8_string io
      end
    end
  end
end

require "mqteelo_gen"
