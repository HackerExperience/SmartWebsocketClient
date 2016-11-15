defmodule SimpleWebsocketClientTest do
  use ExUnit.Case
  doctest SimpleWebsocketClient
  alias SimpleWebsocketClient.Test.Helper.Server
  alias SimpleWebsocketClient.Test.Helper.ListenerLogger
  import ExUnit.CaptureLog

  @moduletag timeout: 2_000
  @test_port 6666

  setup_all do
    {:ok, pid} = Server.run(@test_port)

    {:ok, server: pid}
  end

  setup do
    connection = %SimpleWebsocketClient.Connection{port: @test_port}
    listener = ListenerLogger

    [valid_connection: connection, listener: listener]
  end

  setup ctx do
    :ok
  end

  describe "connection" do
    test "client is able to connect to a WS server", ctx do
      assert {:ok, pid} = SimpleWebsocketClient.connect(ctx[:valid_connection], ctx[:listener])
      SimpleWebsocketClient.disconnect
    end

    test "client successfully disconnects", ctx do
      {:ok, pid} = SimpleWebsocketClient.connect(ctx[:valid_connection], ctx[:listener])
      assert :ok = SimpleWebsocketClient.disconnect
      refute Process.alive?(pid)
    end

    test "workers disconnect gracefully" do
      # TODO
    end
  end

  describe "pool" do
    test "use single connection pool if no pool is specified", ctx do
      {:ok, pid} = SimpleWebsocketClient.connect(ctx[:valid_connection], ctx[:listener])
      pool_name = SimpleWebsocketClient.Pool.default_name
      assert {:ready, 1, 0, _} = :poolboy.status(pool_name)
      SimpleWebsocketClient.disconnect()
    end

    test "pool is properly set up", ctx do
      pool = %SimpleWebsocketClient.Pool{size: 2, overflow: 1, name: :test_pool}
      {:ok, pid} = SimpleWebsocketClient.connect(ctx[:valid_connection], pool, ctx[:listener])

      assert {:ready, pool_size, overflow, _} = :poolboy.status(:test_pool)
      assert pool_size == pool.size
      assert overflow <= pool.overflow

      SimpleWebsocketClient.disconnect()
    end
  end

  describe "send" do
    test "client sends a message to the server (no pool)", ctx do
      {:ok, pid} = SimpleWebsocketClient.connect(ctx[:valid_connection], ctx[:listener])
      assert capture_log(fn ->
        SimpleWebsocketClient.send("MyCoolMessage")
        :timer.sleep(20)
      end) =~ "MyCoolMessage"
      SimpleWebsocketClient.disconnect()
    end

    test "client sends a message to the server (with pool)", ctx do
      pool = %SimpleWebsocketClient.Pool{size: 2, overflow: 1}
      {:ok, pid} = SimpleWebsocketClient.connect(ctx[:valid_connection], pool, ctx[:listener])
      assert capture_log(fn ->
        SimpleWebsocketClient.send("MyPooledMessage")
        :timer.sleep(20)
      end) =~ "MyPooledMessage"
      SimpleWebsocketClient.disconnect()
    end
  end

  describe "receive" do
    test "SWC worker forwards received messages to the listener", ctx do
      {:ok, pid} = SimpleWebsocketClient.connect(ctx[:valid_connection], ctx[:listener])
      assert capture_log(fn ->
        SimpleWebsocketClient.send("MyListenedMessage")
        :timer.sleep(20)
      end) =~ "Received: MyListenedMessage"
      SimpleWebsocketClient.disconnect()
    end
  end

end
