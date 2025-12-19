module MQTeelo
  module Properties
    PAYLOAD_FORMAT_INDICATOR = 0x01
    MESSAGE_EXPIRY_INTERVAL = 0x02
    CONTENT_TYPE = 0x03
    RESPONSE_TOPIC = 0x08
    CORRELATION_DATA = 0x09
    SUBSCRIPTION_IDENTIFIER = 0x0b
    SESSION_EXPIRY_INTERVAL = 0x11
    ASSIGNED_CLIENT_IDENTIFIER = 0x12
    SERVER_KEEP_ALIVE = 0x13
    AUTHENTICATION_METHOD = 0x15
    AUTHENTICATION_DATA = 0x16
    REQUEST_PROBLEM_INFORMATION = 0x17
    WILL_DELAY_INTERVAL = 0x18
    REQUEST_RESPONSE_INFORMATION = 0x19
    RESPONSE_INFORMATION = 0x1a
    SERVER_REFERENCE = 0x1c
    REASON_STRING = 0x1f
    RECEIVE_MAXIMUM = 0x21
    TOPIC_ALIAS_MAXIMUM = 0x22
    TOPIC_ALIAS = 0x23
    MAXIMUM_QOS = 0x24
    RETAIN_AVAILABLE = 0x25
    USER_PROPERTY = 0x26
    MAXIMUM_PACKET_SIZE = 0x27
    WILDCARD_SUBSCRIPTION_AVAILABLE = 0x28
    SUBSCRIPTION_IDENTIFIER_AVAILABLE = 0x29
    SHARED_SUBSCRIPTION_AVAILABLE = 0x2a
  end

  module Reasons
    SUCCESS = 0000
    NORMAL_DISCONNECTION = 0000
    GRANTED_QOS_0 = 0000
    GRANTED_QOS_1 = 0x01
    GRANTED_QOS_2 = 0x02
    DISCONNECT_WITH_WILL_MESSAGE = 0x04
    NO_MATCHING_SUBSCRIBERS = 0x10
    NO_SUBSCRIPTION_EXISTED = 0x11
    CONTINUE_AUTHENTICATION = 0x18
    REAUTHENTICATE = 0x19
    UNSPECIFIED_ERROR = 0x80
    MALFORMED_PACKET = 0x81
    PROTOCOL_ERROR = 0x82
    IMPLEMENTATION_SPECIFIC_ERROR = 0x83
    UNSUPPORTED_PROTOCOL_VERSION = 0x84
    CLIENT_IDENTIFIER_NOT_VALID = 0x85
    BAD_USER_NAME_OR_PASSWORD = 0x86
    NOT_AUTHORIZED = 0x87
    SERVER_UNAVAILABLE = 0x88
    SERVER_BUSY = 0x89
    BANNED = 0x8a
    SERVER_SHUTTING_DOWN = 0x8b
    BAD_AUTHENTICATION_METHOD = 0x8c
    KEEP_ALIVE_TIMEOUT = 0x8d
    SESSION_TAKEN_OVER = 0x8e
    TOPIC_FILTER_INVALID = 0x8f
    TOPIC_NAME_INVALID = 0x90
    PACKET_IDENTIFIER_IN_USE = 0x91
    PACKET_IDENTIFIER_NOT_FOUND = 0x92
    RECEIVE_MAXIMUM_EXCEEDED = 0x93
    TOPIC_ALIAS_INVALID = 0x94
    PACKET_TOO_LARGE = 0x95
    MESSAGE_RATE_TOO_HIGH = 0x96
    QUOTA_EXCEEDED = 0x97
    ADMINISTRATIVE_ACTION = 0x98
    PAYLOAD_FORMAT_INVALID = 0x99
    RETAIN_NOT_SUPPORTED = 0x9a
    QOS_NOT_SUPPORTED = 0x9b
    USE_ANOTHER_SERVER = 0x9c
    SERVER_MOVED = 0x9d
    SHARED_SUBSCRIPTIONS_NOT_SUPPORTED = 0x9e
    CONNECTION_RATE_EXCEEDED = 0x9f
    MAXIMUM_CONNECT_TIME = 0xa0
    SUBSCRIPTION_IDENTIFIERS_NOT_SUPPORTED = 0xa1
    WILDCARD_SUBSCRIPTIONS_NOT_SUPPORTED = 0xa2
  end

  module Packets
    CONNECT = (0x01 << 4)
    CONNACK = (0x02 << 4)
    PUBLISH = (0x03 << 4)
    PUBACK = (0x04 << 4)
    PUBREC = (0x05 << 4)
    PUBREL = (0x06 << 4) | 0x02
    PUBCOMP = (0x07 << 4)
    SUBSCRIBE = (0x08 << 4) | 0x02
    SUBACK = (0x09 << 4)
    UNSUBSCRIBE = (0x0a << 4) | 0x02
    UNSUBACK = (0x0b << 4)
    PINGREQ = (0x0c << 4)
    PINGRESP = (0x0d << 4)
    DISCONNECT = (0x0e << 4)
    AUTH = (0x0f << 4)
  end

  class Connection

    private

    def encode_property id, value, out
      if id == 0x01
        out << value
      elsif id == 0x02
        [value].pack("N", buffer: out)

      elsif id == 0x03
        [value.bytesize, value].pack("na*", buffer: out)

      elsif id == 0x08
        [value.bytesize, value].pack("na*", buffer: out)

      elsif id == 0x09
        [value.bytesize, value].pack("na*", buffer: out)

      elsif id == 0x0b
        [value].pack("R", buffer: out)

      elsif id == 0x11
        [value].pack("N", buffer: out)

      elsif id == 0x12
        [value.bytesize, value].pack("na*", buffer: out)

      elsif id == 0x13
        [value].pack("n", buffer: out)

      elsif id == 0x15
        [value.bytesize, value].pack("na*", buffer: out)

      elsif id == 0x16
        [value.bytesize, value].pack("na*", buffer: out)

      elsif id == 0x17
        out << value
      elsif id == 0x18
        [value].pack("N", buffer: out)

      elsif id == 0x19
        out << value
      elsif id == 0x1a
        [value.bytesize, value].pack("na*", buffer: out)

      elsif id == 0x1c
        [value.bytesize, value].pack("na*", buffer: out)

      elsif id == 0x1f
        [value.bytesize, value].pack("na*", buffer: out)

      elsif id == 0x21
        [value].pack("n", buffer: out)

      elsif id == 0x22
        [value].pack("n", buffer: out)

      elsif id == 0x23
        [value].pack("n", buffer: out)

      elsif id == 0x24
        out << value
      elsif id == 0x25
        out << value
      elsif id == 0x26
        [value[0].bytesize, value[0], value[1].bytesize, value[1]].pack("na*na*", buffer: out)

      elsif id == 0x27
        [value].pack("N", buffer: out)

      elsif id == 0x28
        out << value
      elsif id == 0x29
        out << value
      elsif id == 0x2a
        out << value
      else
      end
    end

    def _handle app, io, id, flags, len
      if id == 0x01
        raise "wrong flags" unless flags == 0000
        handle_connect(app, io, flags, len)
      elsif id == 0x02
        raise "wrong flags" unless flags == 0000
        handle_connack(app, io, flags, len)
      elsif id == 0x03
        handle_publish(app, io, flags, len)
      elsif id == 0x04
        raise "wrong flags" unless flags == 0000
        handle_puback(app, io, flags, len)
      elsif id == 0x05
        raise "wrong flags" unless flags == 0000
        handle_pubrec(app, io, flags, len)
      elsif id == 0x06
        raise "wrong flags" unless flags == 0x02
        handle_pubrel(app, io, flags, len)
      elsif id == 0x07
        raise "wrong flags" unless flags == 0000
        handle_pubcomp(app, io, flags, len)
      elsif id == 0x08
        raise "wrong flags" unless flags == 0x02
        handle_subscribe(app, io, flags, len)
      elsif id == 0x09
        raise "wrong flags" unless flags == 0000
        handle_suback(app, io, flags, len)
      elsif id == 0x0a
        raise "wrong flags" unless flags == 0x02
        handle_unsubscribe(app, io, flags, len)
      elsif id == 0x0b
        raise "wrong flags" unless flags == 0000
        handle_unsuback(app, io, flags, len)
      elsif id == 0x0c
        raise "wrong flags" unless flags == 0000
        handle_pingreq(app, io, flags, len)
      elsif id == 0x0d
        raise "wrong flags" unless flags == 0000
        handle_pingresp(app, io, flags, len)
      elsif id == 0x0e
        raise "wrong flags" unless flags == 0000
        handle_disconnect(app, io, flags, len)
      elsif id == 0x0f
        raise "wrong flags" unless flags == 0000
        handle_auth(app, io, flags, len)
      else
        raise "unknown id #{id}"
      end
    end

    def publish_properties buffer, offset, len
      read = 0
      properties = []
      while read < len
        id = buffer.getbyte(read + offset)
        read += 1
        if id == 0x01 # Payload Format Indicator
            val = buffer.getbyte(read + offset)
            read += 1

        elsif id == 0x02 # Message Expiry Interval
            val = buffer.unpack1("N", offset: read + offset)
            read += 4

        elsif id == 0x03 # Content Type
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x08 # Response Topic
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x09 # Correlation Data
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size) : "".b
            read += size

        elsif id == 0x0b # Subscription Identifier
            val = buffer.unpack1("R", offset: read + offset)
            read += encoded_varint_len(val)

        elsif id == 0x23 # Topic Alias
            val = buffer.unpack1("n", offset: read + offset)
            read += 2

        elsif id == 0x26 # User Property
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val1 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val2 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            val = [val1, val2]

        else
          raise "wrong property #{sprintf("%#04x", id)}"
        end
        properties << [id, val]
      end
      properties
    end

    def will_properties buffer, offset, len
      read = 0
      properties = []
      while read < len
        id = buffer.getbyte(read + offset)
        read += 1
        if id == 0x01 # Payload Format Indicator
            val = buffer.getbyte(read + offset)
            read += 1

        elsif id == 0x02 # Message Expiry Interval
            val = buffer.unpack1("N", offset: read + offset)
            read += 4

        elsif id == 0x03 # Content Type
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x08 # Response Topic
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x09 # Correlation Data
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size) : "".b
            read += size

        elsif id == 0x18 # Will Delay Interval
            val = buffer.unpack1("N", offset: read + offset)
            read += 4

        elsif id == 0x26 # User Property
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val1 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val2 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            val = [val1, val2]

        else
          raise "wrong property #{sprintf("%#04x", id)}"
        end
        properties << [id, val]
      end
      properties
    end

    def subscribe_properties buffer, offset, len
      read = 0
      properties = []
      while read < len
        id = buffer.getbyte(read + offset)
        read += 1
        if id == 0x0b # Subscription Identifier
            val = buffer.unpack1("R", offset: read + offset)
            read += encoded_varint_len(val)

        elsif id == 0x26 # User Property
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val1 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val2 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            val = [val1, val2]

        else
          raise "wrong property #{sprintf("%#04x", id)}"
        end
        properties << [id, val]
      end
      properties
    end

    def connect_properties buffer, offset, len
      read = 0
      properties = []
      while read < len
        id = buffer.getbyte(read + offset)
        read += 1
        if id == 0x11 # Session Expiry Interval
            val = buffer.unpack1("N", offset: read + offset)
            read += 4

        elsif id == 0x15 # Authentication Method
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x16 # Authentication Data
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size) : "".b
            read += size

        elsif id == 0x17 # Request Problem Information
            val = buffer.getbyte(read + offset)
            read += 1

        elsif id == 0x19 # Request Response Information
            val = buffer.getbyte(read + offset)
            read += 1

        elsif id == 0x21 # Receive Maximum
            val = buffer.unpack1("n", offset: read + offset)
            read += 2

        elsif id == 0x22 # Topic Alias Maximum
            val = buffer.unpack1("n", offset: read + offset)
            read += 2

        elsif id == 0x26 # User Property
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val1 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val2 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            val = [val1, val2]

        elsif id == 0x27 # Maximum Packet Size
            val = buffer.unpack1("N", offset: read + offset)
            read += 4

        else
          raise "wrong property #{sprintf("%#04x", id)}"
        end
        properties << [id, val]
      end
      properties
    end

    def connack_properties buffer, offset, len
      read = 0
      properties = []
      while read < len
        id = buffer.getbyte(read + offset)
        read += 1
        if id == 0x11 # Session Expiry Interval
            val = buffer.unpack1("N", offset: read + offset)
            read += 4

        elsif id == 0x12 # Assigned Client Identifier
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x13 # Server Keep Alive
            val = buffer.unpack1("n", offset: read + offset)
            read += 2

        elsif id == 0x15 # Authentication Method
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x16 # Authentication Data
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size) : "".b
            read += size

        elsif id == 0x1a # Response Information
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x1c # Server Reference
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x1f # Reason String
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x21 # Receive Maximum
            val = buffer.unpack1("n", offset: read + offset)
            read += 2

        elsif id == 0x22 # Topic Alias Maximum
            val = buffer.unpack1("n", offset: read + offset)
            read += 2

        elsif id == 0x24 # Maximum QoS
            val = buffer.getbyte(read + offset)
            read += 1

        elsif id == 0x25 # Retain Available
            val = buffer.getbyte(read + offset)
            read += 1

        elsif id == 0x26 # User Property
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val1 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val2 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            val = [val1, val2]

        elsif id == 0x27 # Maximum Packet Size
            val = buffer.unpack1("N", offset: read + offset)
            read += 4

        elsif id == 0x28 # Wildcard Subscription Available
            val = buffer.getbyte(read + offset)
            read += 1

        elsif id == 0x29 # Subscription Identifier Available
            val = buffer.getbyte(read + offset)
            read += 1

        elsif id == 0x2a # Shared Subscription Available
            val = buffer.getbyte(read + offset)
            read += 1

        else
          raise "wrong property #{sprintf("%#04x", id)}"
        end
        properties << [id, val]
      end
      properties
    end

    def disconnect_properties buffer, offset, len
      read = 0
      properties = []
      while read < len
        id = buffer.getbyte(read + offset)
        read += 1
        if id == 0x11 # Session Expiry Interval
            val = buffer.unpack1("N", offset: read + offset)
            read += 4

        elsif id == 0x1c # Server Reference
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x1f # Reason String
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x26 # User Property
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val1 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val2 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            val = [val1, val2]

        else
          raise "wrong property #{sprintf("%#04x", id)}"
        end
        properties << [id, val]
      end
      properties
    end

    def auth_properties buffer, offset, len
      read = 0
      properties = []
      while read < len
        id = buffer.getbyte(read + offset)
        read += 1
        if id == 0x15 # Authentication Method
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x16 # Authentication Data
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size) : "".b
            read += size

        elsif id == 0x1f # Reason String
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x26 # User Property
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val1 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val2 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            val = [val1, val2]

        else
          raise "wrong property #{sprintf("%#04x", id)}"
        end
        properties << [id, val]
      end
      properties
    end

    def puback_properties buffer, offset, len
      read = 0
      properties = []
      while read < len
        id = buffer.getbyte(read + offset)
        read += 1
        if id == 0x1f # Reason String
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x26 # User Property
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val1 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val2 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            val = [val1, val2]

        else
          raise "wrong property #{sprintf("%#04x", id)}"
        end
        properties << [id, val]
      end
      properties
    end

    def pubrec_properties buffer, offset, len
      read = 0
      properties = []
      while read < len
        id = buffer.getbyte(read + offset)
        read += 1
        if id == 0x1f # Reason String
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x26 # User Property
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val1 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val2 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            val = [val1, val2]

        else
          raise "wrong property #{sprintf("%#04x", id)}"
        end
        properties << [id, val]
      end
      properties
    end

    def pubrel_properties buffer, offset, len
      read = 0
      properties = []
      while read < len
        id = buffer.getbyte(read + offset)
        read += 1
        if id == 0x1f # Reason String
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x26 # User Property
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val1 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val2 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            val = [val1, val2]

        else
          raise "wrong property #{sprintf("%#04x", id)}"
        end
        properties << [id, val]
      end
      properties
    end

    def pubcomp_properties buffer, offset, len
      read = 0
      properties = []
      while read < len
        id = buffer.getbyte(read + offset)
        read += 1
        if id == 0x1f # Reason String
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x26 # User Property
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val1 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val2 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            val = [val1, val2]

        else
          raise "wrong property #{sprintf("%#04x", id)}"
        end
        properties << [id, val]
      end
      properties
    end

    def suback_properties buffer, offset, len
      read = 0
      properties = []
      while read < len
        id = buffer.getbyte(read + offset)
        read += 1
        if id == 0x1f # Reason String
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x26 # User Property
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val1 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val2 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            val = [val1, val2]

        else
          raise "wrong property #{sprintf("%#04x", id)}"
        end
        properties << [id, val]
      end
      properties
    end

    def unsuback_properties buffer, offset, len
      read = 0
      properties = []
      while read < len
        id = buffer.getbyte(read + offset)
        read += 1
        if id == 0x1f # Reason String
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

        elsif id == 0x26 # User Property
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val1 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val2 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            val = [val1, val2]

        else
          raise "wrong property #{sprintf("%#04x", id)}"
        end
        properties << [id, val]
      end
      properties
    end

    def unsubscribe_properties buffer, offset, len
      read = 0
      properties = []
      while read < len
        id = buffer.getbyte(read + offset)
        read += 1
        if id == 0x26 # User Property
            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val1 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            size = buffer.unpack1("n", offset: read + offset)
            read += 2
            val2 = size.positive? ? buffer.byteslice(offset + read, size).force_encoding('UTF-8') : ""
            read += size

            val = [val1, val2]

        else
          raise "wrong property #{sprintf("%#04x", id)}"
        end
        properties << [id, val]
      end
      properties
    end
  end
end
