require "socket"
require "mqteelo"

server = TCPServer.new("127.0.0.1", 1883)

def handle_request(fd, server)
  request_ractor = Ractor.new(fd, server) do |fd, app|
    s = IO.for_fd(fd)
    app.handle s
    #byte = s.readbyte
    #flags = byte & 0xF
    #packet_type = byte >> 4
    #p packet_type
    #packet_size = read_varint(s)
    #p s.read 6   # protocol name
    #p s.readbyte # protocol version
    #conn_flags = s.readbyte # connect flags
    #if (conn_flags & (1 << 7)) > 0
    #  p "username"
    #end
    #if (conn_flags & (1 << 6)) > 0
    #  p "password"
    #end
    #if (conn_flags & (1 << 5)) > 0
    #  p "will retain"
    #end
    #qos = conn_flags & 0b11000
    #p QOS: qos
    #if (conn_flags & (1 << 2)) > 0
    #  p "will flag"
    #end

    #if (conn_flags & (1 << 1)) > 0
    #  p "clean start"
    #end

    #p read_2byte_int(s) # keep alive
    #p read_varint(s) # property len
    #p s.readbyte
    #p s.readbyte
    #p s.readbyte

  end
end

app = MQTeelo::Server.new(nil).freeze
accept_ractor = Ractor.new(server, app) do |server, app|
  while sockfd = server.sysaccept
    handle_request(sockfd, app)
  end
end.join
