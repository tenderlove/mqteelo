# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require "mqteelo"

module MQTeelo
  class ServerTest < Minitest::Test
    class App
      attr_reader :events

      def initialize
        @events = []
      end

      def on_connect version:,
                     will_retain:,
                     qos:,
                     clean_start:,
                     keep_alive:,
                     connect_properties:,
                     will_properties:,
                     will_topic:,
                     will_payload:,
                     client_id:,
                     username:,
                     password:
        @events << {
          version:,
          will_retain:,
          qos:,
          clean_start:,
          keep_alive:,
          connect_properties:,
          will_properties:,
          will_topic:,
          will_payload:,
          client_id:,
          username:,
          password:
        }
      end
    end

    class ProxyApp
      def initialize conn
        @conn = conn
      end

      def on_connect(...)
        @conn.send_connect(...)
      end
    end

    def test_handle_will
      app = App.new
      bytes = "\x10&\x00\x04MQTT\x05\xC6\x00<\x03!\x00\x14\x00\x00\x00\x00\afoo/bar\x00\x00\x00\x03pub\x00\x03sub".b
      io = StringIO.new bytes
      conn = Connection.new io, app
      conn.receive
      assert_equal 1, app.events.length
      assert_equal [{version: 5, will_retain: false, qos: 0, clean_start: true, keep_alive: 60, connect_properties: [[Properties::RECEIVE_MAXIMUM, 20]], will_properties: [], will_topic: "foo/bar", will_payload: "", client_id: "", username: "pub", password: "sub"}], app.events
    end

    def test_roundtrip
      output = StringIO.new "".b
      app = ProxyApp.new(Connection.new(output, nil))

      bytes = "\x10&\x00\x04MQTT\x05\xC6\x00<\x03!\x00\x14\x00\x00\x00\x00\afoo/bar\x00\x00\x00\x03pub\x00\x03sub".b
      server = Connection.new StringIO.new(bytes), app
      server.receive
      assert_equal bytes, output.string
    end


    def test_send_connect
      bytes = "\x10&\x00\x04MQTT\x05\xC6\x00<\x03!\x00\x14\x00\x00\x00\x00\afoo/bar\x00\x00\x00\x03pub\x00\x03sub".b
      io = StringIO.new "".b
      conn = Connection.new io, nil
      conn.send_connect will_topic: "foo/bar", username: "pub", password: "sub"
      assert_equal bytes, io.string
    end
  end
end
