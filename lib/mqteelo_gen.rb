class MQTeelo
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

  def handle io, id, flags
    if id == 0x01
      raise "wrong flags" unless flags == 0000
      handle_connect(io, flags)
    elseif id == 0x02
      raise "wrong flags" unless flags == 0000
      handle_connack(io, flags)
    elseif id == 0x03
      handle_publish(io, flags)
    elseif id == 0x04
      raise "wrong flags" unless flags == 0000
      handle_puback(io, flags)
    elseif id == 0x05
      raise "wrong flags" unless flags == 0000
      handle_pubrec(io, flags)
    elseif id == 0x06
      raise "wrong flags" unless flags == 0x02
      handle_pubrel(io, flags)
    elseif id == 0x07
      raise "wrong flags" unless flags == 0000
      handle_pubcomp(io, flags)
    elseif id == 0x08
      raise "wrong flags" unless flags == 0x02
      handle_subscribe(io, flags)
    elseif id == 0x09
      raise "wrong flags" unless flags == 0000
      handle_suback(io, flags)
    elseif id == 0x0a
      raise "wrong flags" unless flags == 0x02
      handle_unsubscribe(io, flags)
    elseif id == 0x0b
      raise "wrong flags" unless flags == 0000
      handle_unsuback(io, flags)
    elseif id == 0x0c
      raise "wrong flags" unless flags == 0000
      handle_pingreq(io, flags)
    elseif id == 0x0d
      raise "wrong flags" unless flags == 0000
      handle_pingresp(io, flags)
    elseif id == 0x0e
      raise "wrong flags" unless flags == 0000
      handle_disconnect(io, flags)
    elseif id == 0x0f
      raise "wrong flags" unless flags == 0000
      handle_auth(io, flags)
    else
      raise "unknown id #{id}"
    end
  end

  private

  def publish_properties io, id
    if id == 0x01 # Payload Format Indicator
      io.getbyte
    elseif id == 0x02 # Message Expiry Interval
      io.getbyte << 24 | io.getbyte << 16 | io.getbyte << 8 | io.getbyte
    elseif id == 0x03 # Content Type
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x08 # Response Topic
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x09 # Correlation Data
      io.read(io.getbyte << 8 | io.getbyte)
    elseif id == 0x0b # Subscription Identifier
      read_varint(io)
    elseif id == 0x23 # Topic Alias
      io.getbyte << 8 | io.getbyte
    elseif id == 0x26 # User Property
      [io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8'), io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')]
    else
      raise "wrong property #{id}"
    end
  end

  def will_properties io, id
    if id == 0x01 # Payload Format Indicator
      io.getbyte
    elseif id == 0x02 # Message Expiry Interval
      io.getbyte << 24 | io.getbyte << 16 | io.getbyte << 8 | io.getbyte
    elseif id == 0x03 # Content Type
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x08 # Response Topic
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x09 # Correlation Data
      io.read(io.getbyte << 8 | io.getbyte)
    elseif id == 0x18 # Will Delay Interval
      io.getbyte << 24 | io.getbyte << 16 | io.getbyte << 8 | io.getbyte
    elseif id == 0x26 # User Property
      [io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8'), io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')]
    else
      raise "wrong property #{id}"
    end
  end

  def subscribe_properties io, id
    if id == 0x0b # Subscription Identifier
      read_varint(io)
    elseif id == 0x26 # User Property
      [io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8'), io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')]
    else
      raise "wrong property #{id}"
    end
  end

  def connect_properties io, id
    if id == 0x11 # Session Expiry Interval
      io.getbyte << 24 | io.getbyte << 16 | io.getbyte << 8 | io.getbyte
    elseif id == 0x15 # Authentication Method
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x16 # Authentication Data
      io.read(io.getbyte << 8 | io.getbyte)
    elseif id == 0x17 # Request Problem Information
      io.getbyte
    elseif id == 0x19 # Request Response Information
      io.getbyte
    elseif id == 0x21 # Receive Maximum
      io.getbyte << 8 | io.getbyte
    elseif id == 0x22 # Topic Alias Maximum
      io.getbyte << 8 | io.getbyte
    elseif id == 0x26 # User Property
      [io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8'), io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')]
    elseif id == 0x27 # Maximum Packet Size
      io.getbyte << 24 | io.getbyte << 16 | io.getbyte << 8 | io.getbyte
    else
      raise "wrong property #{id}"
    end
  end

  def connack_properties io, id
    if id == 0x11 # Session Expiry Interval
      io.getbyte << 24 | io.getbyte << 16 | io.getbyte << 8 | io.getbyte
    elseif id == 0x12 # Assigned Client Identifier
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x13 # Server Keep Alive
      io.getbyte << 8 | io.getbyte
    elseif id == 0x15 # Authentication Method
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x16 # Authentication Data
      io.read(io.getbyte << 8 | io.getbyte)
    elseif id == 0x1a # Response Information
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x1c # Server Reference
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x1f # Reason String
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x21 # Receive Maximum
      io.getbyte << 8 | io.getbyte
    elseif id == 0x22 # Topic Alias Maximum
      io.getbyte << 8 | io.getbyte
    elseif id == 0x24 # Maximum QoS
      io.getbyte
    elseif id == 0x25 # Retain Available
      io.getbyte
    elseif id == 0x26 # User Property
      [io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8'), io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')]
    elseif id == 0x27 # Maximum Packet Size
      io.getbyte << 24 | io.getbyte << 16 | io.getbyte << 8 | io.getbyte
    elseif id == 0x28 # Wildcard Subscription Available
      io.getbyte
    elseif id == 0x29 # Subscription Identifier Available
      io.getbyte
    elseif id == 0x2a # Shared Subscription Available
      io.getbyte
    else
      raise "wrong property #{id}"
    end
  end

  def disconnect_properties io, id
    if id == 0x11 # Session Expiry Interval
      io.getbyte << 24 | io.getbyte << 16 | io.getbyte << 8 | io.getbyte
    elseif id == 0x1c # Server Reference
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x1f # Reason String
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x26 # User Property
      [io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8'), io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')]
    else
      raise "wrong property #{id}"
    end
  end

  def auth_properties io, id
    if id == 0x15 # Authentication Method
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x16 # Authentication Data
      io.read(io.getbyte << 8 | io.getbyte)
    elseif id == 0x1f # Reason String
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x26 # User Property
      [io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8'), io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')]
    else
      raise "wrong property #{id}"
    end
  end

  def puback_properties io, id
    if id == 0x1f # Reason String
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x26 # User Property
      [io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8'), io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')]
    else
      raise "wrong property #{id}"
    end
  end

  def pubrec_properties io, id
    if id == 0x1f # Reason String
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x26 # User Property
      [io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8'), io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')]
    else
      raise "wrong property #{id}"
    end
  end

  def pubrel_properties io, id
    if id == 0x1f # Reason String
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x26 # User Property
      [io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8'), io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')]
    else
      raise "wrong property #{id}"
    end
  end

  def pubcomp_properties io, id
    if id == 0x1f # Reason String
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x26 # User Property
      [io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8'), io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')]
    else
      raise "wrong property #{id}"
    end
  end

  def suback_properties io, id
    if id == 0x1f # Reason String
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x26 # User Property
      [io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8'), io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')]
    else
      raise "wrong property #{id}"
    end
  end

  def unsuback_properties io, id
    if id == 0x1f # Reason String
      io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')
    elseif id == 0x26 # User Property
      [io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8'), io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')]
    else
      raise "wrong property #{id}"
    end
  end

  def unsubscribe_properties io, id
    if id == 0x26 # User Property
      [io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8'), io.read(io.getbyte << 8 | io.getbyte).force_encoding('UTF-8')]
    else
      raise "wrong property #{id}"
    end
  end

end
