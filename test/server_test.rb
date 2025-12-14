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

      def on_connect conn,
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

      def on_connack _, session_present:, reason:, properties:
        @events << { session_present:, reason:, properties: }
      end
    end

    class Echo
      def initialize out_io, conn
        @out_io = out_io
        @conn = conn
      end

      def on_connect(conn, ...)
        @conn.send_connect(@out_io, ...)
      end

      def on_connack(conn, ...)
        @conn.send_connack(@out_io, ...)
      end
    end

    def test_handle_connect
      app = App.new
      bytes = "\x10&\x00\x04MQTT\x05\xC6\x00<\x03!\x00\x14\x00\x00\x00\x00\afoo/bar\x00\x00\x00\x03pub\x00\x03sub".b
      io = StringIO.new bytes
      conn = make_connection app
      conn.receive io
      assert_predicate io, :eof?
      assert_equal 1, app.events.length
      assert_equal [{version: 5, will_retain: false, qos: 0, clean_start: true, keep_alive: 60, connect_properties: [[Properties::RECEIVE_MAXIMUM, 20]], will_properties: [], will_topic: "foo/bar", will_payload: "", client_id: "", username: "pub", password: "sub"}], app.events
    end

    def test_roundtrip
      output = StringIO.new "".b
      app = Echo.new(output, make_connection(nil))

      bytes = "\x10&\x00\x04MQTT\x05\xC6\x00<\x03!\x00\x14\x00\x00\x00\x00\afoo/bar\x00\x00\x00\x03pub\x00\x03sub".b
      io = StringIO.new(bytes)
      server = make_connection app
      server.receive io
      assert_equal bytes, output.string
    end


    def test_send_connect
      bytes = "\x10&\x00\x04MQTT\x05\xC6\x00<\x03!\x00\x14\x00\x00\x00\x00\afoo/bar\x00\x00\x00\x03pub\x00\x03sub".b
      io = StringIO.new "".b
      conn = make_connection nil
      conn.send_connect io, will_topic: "foo/bar", username: "pub", password: "sub"
      assert_equal bytes, io.string
    end

    def test_connack
      bytes = " 5\x00\x002\"\x00\n\x12\x00)auto-FB891F1A-C8A1-76AA-013A-73DA6FEBEF26!\x00\n"
      io = StringIO.new bytes
      app = App.new
      conn = make_connection app
      conn.receive io
      assert_predicate io, :eof?
      assert_equal 1, app.events.length
      assert_equal [{session_present: false, reason: 0, properties: [[34, 10], [18, "auto-FB891F1A-C8A1-76AA-013A-73DA6FEBEF26"], [33, 10]]}], app.events
    end

    def test_connack_roundtrip
      output = StringIO.new "".b
      app = Echo.new(output, make_connection(nil))

      bytes = " 5\x00\x002\"\x00\n\x12\x00)auto-FB891F1A-C8A1-76AA-013A-73DA6FEBEF26!\x00\n"
      io = StringIO.new(bytes)
      server = make_connection app
      server.receive io
      assert_equal bytes, output.string
    end

    def make_connection app
      Connection.new app
    end
  end
end
