require "socket"
require "mqteelo"

server = TCPServer.new("127.0.0.1", 1883)

class App
  def on_connect conn, **kw
    p kw
  end
end

def handle_request(fd, app)
  request_ractor = Ractor.new(fd, app) do |fd, app|
    s = IO.for_fd(fd)
    app = MQTeelo::Connection.new(s, app)
    app.receive
  end
end

app = App.new.freeze
accept_ractor = Ractor.new(server, app) do |server, app|
  while sockfd = server.sysaccept
    handle_request(sockfd, app)
  end
end.join
