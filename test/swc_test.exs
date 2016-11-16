defmodule SmartWebsocketClientTest do
  use ExUnit.Case
  doctest SmartWebsocketClient
  alias SmartWebsocketClient.Test.Helper.Server
  alias SmartWebsocketClient.Test.Helper.ListenerLogger
  import ExUnit.CaptureLog

  @moduletag timeout: 2_000
  @test_port 6666

  setup_all do
    {:ok, pid} = Server.run(@test_port)

    {:ok, server: pid}
  end

  setup do
    connection = %SmartWebsocketClient.Connection{port: @test_port}
    listener = ListenerLogger

    {:ok , [connection: connection, listener: listener]}
  end

  describe "connection" do
    test "client is able to connect to a WS server", ctx do
      assert {:ok, _} = SmartWebsocketClient.connect(ctx.connection, ctx.listener)
      SmartWebsocketClient.disconnect()
    end

    test "client successfully disconnects", ctx do
      {:ok, pid} = SmartWebsocketClient.connect(ctx.connection, ctx.listener)
      assert SmartWebsocketClient.disconnect()
      refute Process.alive?(pid)
    end

    test "workers disconnect gracefully" do
      # TODO
    end
  end

  describe "pool" do
    test "use single connection pool if no pool is specified", ctx do
      SmartWebsocketClient.connect(ctx.connection, ctx.listener)
      pool_name = SmartWebsocketClient.Pool.default_name()
      assert {:ready, 1, 0, _} = :poolboy.status(pool_name)
      SmartWebsocketClient.disconnect()
    end

    test "pool is properly set up", ctx do
      pool = %SmartWebsocketClient.Pool{size: 2, overflow: 1, name: :test_pool}
      SmartWebsocketClient.connect(ctx.connection, ctx.listener, pool)

      assert {:ready, pool_size, overflow, _} = :poolboy.status(:test_pool)
      assert pool_size == pool.size
      assert overflow <= pool.overflow

      SmartWebsocketClient.disconnect()
    end
  end

  describe "send" do
    test "client sends a message to the server (no pool)", ctx do
      SmartWebsocketClient.connect(ctx.connection, ctx.listener)
      message = "MyCoolMessage"
      log_msg = capture_log(fn ->
        SmartWebsocketClient.send(message)
        :timer.sleep(10)
      end)
      assert log_msg =~ message
      SmartWebsocketClient.disconnect()
    end

    test "client sends a message to the server (with pool)", ctx do
      pool = %SmartWebsocketClient.Pool{size: 2, overflow: 1}
      SmartWebsocketClient.connect(ctx.connection, ctx.listener, pool)
      message = "MyPooledMessage"
      log_msg = capture_log(fn ->
        SmartWebsocketClient.send(message)
        :timer.sleep(10)
      end)
      assert log_msg =~ message
      SmartWebsocketClient.disconnect()
    end

    test "client is able to send a map (converts to json)", ctx do
      SmartWebsocketClient.connect(ctx.connection, ctx.listener)
      log_msg = capture_log(fn ->
        SmartWebsocketClient.send(%{my: "map"})
        :timer.sleep(10)
      end)
      assert log_msg =~ ~s/{"my":"map"}/
      SmartWebsocketClient.disconnect()
    end
  end

  describe "receive" do
    test "SWC worker forwards received messages to the listener", ctx do
      SmartWebsocketClient.connect(ctx.connection, ctx.listener)
      message = "MyListenedMessage"
      log_msg = capture_log(fn ->
        SmartWebsocketClient.send(message)
        :timer.sleep(10)
      end)
      assert log_msg =~ message
      SmartWebsocketClient.disconnect()
    end
  end

  describe "ping" do
    test "SWC automatically handles ping messages", ctx do
      SmartWebsocketClient.connect(ctx.connection, ctx.listener)

      request_ping = fn ->
        log_msg = capture_log(fn ->
          SmartWebsocketClient.send("send_me_ping")
          :timer.sleep(10)
        end)
        assert log_msg =~ "server received pong"
      end
      for _ <- 0..10, do: request_ping.()

      SmartWebsocketClient.disconnect()
    end
  end
end
