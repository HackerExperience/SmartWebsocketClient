defmodule SimpleWebsocketClientTest do
  use ExUnit.Case
  doctest SimpleWebsocketClient
  alias SimpleWebsocketClient.Test.Helper.Server

  @moduletag timeout: 3_000
  @test_port 6666

  setup_all do
    {:ok, pid} = Server.run(@test_port)

    {:ok, server: pid}
  end

  setup do
    connection = %SimpleWebsocketClient.ConnectionConfig{port: @test_port}
    listener = ReturnListener

    [valid_connection: connection, listener: listener]
  end

  setup ctx do
    :ok
  end

  describe "connection" do
    test "client is able to connect to a WS server", ctx do
      assert {:ok, pid} = SimpleWebsocketClient.connect(ctx[:valid_connection], ctx[:listener])
      SimpleWebsocketClient.disconnect(pid, :websocket_pool)
    end

    test "client successfully disconnects", ctx do
      {:ok, pid} = SimpleWebsocketClient.connect(ctx[:valid_connection], ctx[:listener])
      assert :ok = SimpleWebsocketClient.disconnect(pid, :websocket_pool)
      refute Process.alive?(pid)
    end

    test "workers disconnect gracefully" do
      # TODO
    end
  end

  describe "pool" do
    test "use single connection pool if no pool is specified", ctx do
      {:ok, pid} = SimpleWebsocketClient.connect(ctx[:valid_connection], ctx[:listener])
      pool_name = SimpleWebsocketClient.PoolConfig.default_name
      assert {:ready, 1, 0, _} = :poolboy.status(pool_name)
      SimpleWebsocketClient.disconnect(pid, pool_name)
    end

    test "pool is properly set up", ctx do
      pool = %SimpleWebsocketClient.PoolConfig{size: 2, overflow: 1, name: :test_pool}
      {:ok, pid} = SimpleWebsocketClient.connect(ctx[:valid_connection], pool, ctx[:listener])

      assert {:ready, pool_size, overflow, _} = :poolboy.status(:test_pool)
      assert pool_size == pool.size
      assert overflow <= pool.overflow

      SimpleWebsocketClient.disconnect(pid, pool.name)
    end
  end

end

defmodule ReturnListener do

    use SimpleWebsocketClient.Listener

    def on_receive(msg) do
      msg
    end
end
