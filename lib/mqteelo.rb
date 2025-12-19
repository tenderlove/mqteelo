require "mqteelo/utils"

module MQTeelo
  class Connection
    include Utils

    def receive app, io
      byte = io.readbyte
      flags = byte & 0xF
      type = byte >> 4
      size = read_varint(io)

      _handle app, io, type, flags, io.read(size)
    end

    def send_connect io,
                     version: 5,
                     will_retain: false,
                     qos: 0,
                     clean_start: true,
                     keep_alive: 60,
                     properties: [[ Properties::RECEIVE_MAXIMUM, 20 ]],
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
      [ version, conn_flags, keep_alive ].pack("CCn", buffer: packet)

      encode_properties(properties, packet)
      encode_utf8_string(client_id, packet)

      if will_topic
        encode_properties(will_properties, packet)
        [
          will_topic.bytesize, will_topic,
          will_payload.bytesize, will_payload
        ].pack("na*na*", buffer: packet)
      end

      encode_utf8_string(username, packet) if username
      encode_utf8_string(password, packet) if password

      io.putc Packets::CONNECT
      encode_varint2(packet.bytesize, io)
      io.write packet
      io.flush
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
      io.flush
    end

    def send_publish io, dup:, qos:, retain:, topic:, packet_id:, properties:, payload:
      flags = (dup ? 0x8 : 0x0) | (qos << 1) | (retain ? 0x1 : 0)

      packet = "".b
      encode_utf8_string(topic, packet)

      if qos.positive?
        encode_2byte_int(packet_id, packet)
      end

      encode_properties(properties, packet)

      len = packet.bytesize + payload.bytesize

      io.putc Packets::PUBLISH | flags
      encode_varint2(len, io)
      io.write packet
      io.write payload
      io.flush
    end

    def send_disconnect io, reason:, properties:
      if reason
        raise NotImplementedError
      else
        io.putc Packets::DISCONNECT
        io.putc 0
      end
    end

    def send_subscribe io, packet_id:, properties:, filters:
      packet = "".b
      encode_2byte_int(packet_id, packet)
      encode_properties(properties, packet)
      filters.each { |filter, qos|
        encode_utf8_string(filter, packet)
        packet << qos.chr
      }
      io.putc Packets::SUBSCRIBE
      encode_varint2(packet.bytesize, io)
      io.write packet
      io.flush
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

    def handle_subscribe app, io, flags, buffer
      packet_id, prop_len = buffer.unpack("nR")
      offset = encoded_varint_len(prop_len) + 2
      properties = subscribe_properties buffer, offset, prop_len
      offset += prop_len

      filters = []
      len = buffer.bytesize
      while offset < len
        filter = read_utf8_string buffer, offset
        offset += (filter.bytesize + 2)
        qos = buffer.getbyte(offset)
        offset += 1
        filters << [filter, qos]
      end
      app.on_subscribe self, io, packet_id:, properties:, filters:
    end

    def handle_publish app, io, flags, buffer
      dup = flags[3].positive?
      qos = (flags >> 1) & 0x3
      retain = flags[0].positive?

      topic = read_utf8_string buffer, 0
      offset = topic.bytesize + 2

      packet_id = nil
      if qos.positive?
        packet_id = buffer.unpack1("n", offset:)
        offset += 2
      end
      prop_len = buffer.unpack1("R", offset:)
      offset += encoded_varint_len(prop_len)

      properties = publish_properties buffer, offset, prop_len
      offset += prop_len

      remaining = buffer.bytesize - offset
      payload = buffer.byteslice(offset, remaining)
      app.on_publish self, io, dup:, qos:, retain:, packet_id:, topic:, properties:, payload:
    end

    def handle_connect app, io, flags, buffer
      will_retain = false
      clean_start = false

      _, version, conn_flags, keep_alive, prop_len = buffer.unpack("a6CCnR")

      if (conn_flags & (1 << 5)) > 0
        will_retain = true
      end
      qos = conn_flags & 0b11000

      if (conn_flags & (1 << 1)) > 0
        clean_start = true
      end

      offset = 6 + 1 + 1 + 2 + encoded_varint_len(prop_len)

      properties = connect_properties buffer, offset, prop_len

      offset += prop_len

      client_id = read_utf8_string buffer, offset

      offset += (client_id.bytesize + 2)

      if (conn_flags & (1 << 2)) > 0
        will_prop_len = buffer.unpack1("R", offset:)
        offset += encoded_varint_len(will_prop_len)
        will_properties = will_properties buffer, offset, will_prop_len
        offset += will_prop_len
        will_topic = read_utf8_string buffer, offset
        offset += (will_topic.bytesize + 2)
        will_payload = read_binary_string buffer, offset
        offset += (will_payload.bytesize + 2)
      end

      if (conn_flags & (1 << 7)) > 0 # username
        username = read_utf8_string buffer, offset
        offset += (username.bytesize + 2)
      end
      if (conn_flags & (1 << 6)) > 0 # password
        password = read_utf8_string buffer, offset
        offset += (password.bytesize + 2)
      end
      app.on_connect self, io, version:, will_retain:, qos:, clean_start:, keep_alive:,
        properties:, will_properties:, will_topic:, will_payload:,
        client_id:, username:, password:
    end

    def handle_disconnect app, io, _, buffer
      unless buffer.empty?
        raise NotImplementedError # we need a test for this
        reason = buffer.getbyte(0)
        properties = disconnect_properties io, read_varint(io)
      end

      app.on_disconnect self, io, reason:, properties:
    end

    def handle_connack app, io, _, buffer
      flags = buffer.getbyte(0)
      raise if (flags & 0xFE).positive?
      session_present = flags[0].positive?
      reason = buffer.getbyte(1)
      proplen = buffer.unpack1("R", offset: 2)
      properties = connack_properties buffer, encoded_varint_len(proplen) + 2, proplen
      app.on_connack self, io, session_present:, reason:, properties:
    end
  end
end

require "mqteelo_gen"
