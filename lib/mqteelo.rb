require "mqteelo/utils"

module MQTeelo
  class Connection
    include Utils

    def initialize app
      @app = app
    end

    def receive io
      byte = io.readbyte
      flags = byte & 0xF
      type = byte >> 4
      size = read_varint(io)

      _handle io, type, flags, size
    end

    def send_connect io,
                     version: 5,
                     will_retain: false,
                     qos: 0,
                     clean_start: true,
                     keep_alive: 60,
                     connect_properties: [[ Properties::RECEIVE_MAXIMUM, 20 ]],
                     will_properties: [],
                     will_topic: nil,
                     will_payload: "",
                     client_id: "",
                     username: nil,
                     password: nil

      conn_flags = qos
      conn_flags |= 1 << 1 if clean_start
      conn_flags |= 1 << 2 if will_topic
      conn_flags |= 1 << 5 if will_retain
      conn_flags |= 1 << 6 if password
      conn_flags |= 1 << 7 if username

      packet = "\x00\x04MQTT".b
      [ version, conn_flags ].pack("CC", buffer: packet)
      encode_2byte_int(keep_alive, packet)

      encode_properties(connect_properties, packet)
      encode_utf8_string(client_id, packet)

      if will_topic
        encode_properties(will_properties, packet)
        encode_utf8_string(will_topic, packet)
        encode_binary_string(will_payload, packet)
      end

      encode_utf8_string(username, packet) if username
      encode_utf8_string(password, packet) if password

      io.putc Packets::CONNECT
      encode_varint2(packet.bytesize, io)
      io.write packet
    end

    def send_connack io, session_present:, reason:, properties:
      packet = if session_present
        "\x01".b
      else
        "\x00".b
      end

      [reason].pack("C", buffer: packet)
      encode_properties(properties, packet)
      io.putc Packets::CONNACK
      encode_varint2(packet.bytesize, io)
      io.write packet
    end

    private

    def encode_properties props, packet
      buf = "".b
      props.each do |id, val|
        buf << id
        encode_property(id, val, buf)
      end
      encode_varint(buf.bytesize, packet)
      packet << buf
    end

    def handle_connect io, flags, len
      will_retain = false
      clean_start = false

      io.read 6   # protocol name
      version = io.readbyte # protocol version

      conn_flags = io.readbyte # connect flags
      if (conn_flags & (1 << 5)) > 0
        will_retain = true
      end
      qos = conn_flags & 0b11000

      if (conn_flags & (1 << 1)) > 0
        clean_start = true
      end

      keep_alive = read_2byte_int(io) # keep alive

      connect_properties = self.connect_properties io, read_varint(io)

      client_id = read_utf8_string io

      if (conn_flags & (1 << 2)) > 0
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
      @app.on_connect self, version:, will_retain:, qos:, clean_start:, keep_alive:,
        connect_properties:, will_properties:, will_topic:, will_payload:,
        client_id:, username:, password:
    end

    def handle_connack io, _, _
      flags = io.readbyte
      raise if (flags & 0xFE).positive?
      session_present = flags[0].positive?
      reason = io.readbyte
      properties = self.connack_properties io, read_varint(io)
      @app.on_connack self, session_present:, reason:, properties:
    end
  end
end

require "mqteelo_gen"
