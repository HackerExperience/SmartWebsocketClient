defmodule SmartWebsocketClient do
  @moduledoc """
  `SmartWebsocketClient` is a (not-so) smart websocket client with pool support.

  The main goal of this library is to provide a simple interface to send and
  receive websocket messages. Have in mind that this is only a *client*, if you
  want a *server* take a look at [Cowboy](https://github.com/ninenines/cowboy).
  There is a simple implementation of a websocket server at `test/helper/server.ex`,
  which is a helper to test the client.

  The client will spawn two processes for each socket. One is responsible for
  saving the socket state in a pool, and the other listens for new messages.

  ## Pool

  SWC adds support for pools through [poolboy](https://github.com/devinus/poolboy)
  (hopefully a twink?). If you do not specify a pool (i.e. you want only one
  websocket connection), then a pool of one connection is created. Take a look
  at `SmartWebsocketClient.Pool` for details.

  ## Usage

  Connecting and sending/receiving messages is very straightforward. Here's an
  example:

      defmodule MyClient do
        alias SmartWebsocketClient.{Connection, Pool}

        def run do
          connection = %Connection{host: "127.0.0.1", port: 80, path: "/"}
          pool = %Pool{size: 10, overflow: 5}
          SmartWebsocketClient.connect(connection, MyListener, pool)
          SmartWebsocketClient.send("My message")

          # If you don't want to run the client forever, uncomment the line below
          #SmartWebsocketClient.disconnect()
        end
      end

      defmodule MyListener do
        use SmartWebsocketClient.Listener

        def on_receive(msg) do
          IO.puts "Message received!"
          IO.inspect msg
        end
      end

  Hopefully the above example gives an idea of the library's interface. You don't
  need to specify a pool if you do not want one. Use `connect/2` instead.

  ## Listener

  The `SmartWebsocketClient.Listener` is a behaviour that allows you to act on
  received messages. It has a very simple interface, as you can see in the example.
  As a behaviour, you are required to implement the
  `c:SmartWebsocketClient.Listener.on_receive/1` callback. You can also extend
  the behaviour to better suit your needs. Take a look at
  `SmartWebsocketClient.Listener` for details.

  The default Listener behaviour automatically handles ping messages.

  """
  use Supervisor
  import Supervisor.Spec

  @single_connection_pool %SmartWebsocketClient.Pool{size: 1, overflow: 0}

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [])
  end

  @doc false
  def init({connection, listener, pool}) do
    poolboy_config = [
      name: {:local, pool.name},
      worker_module: pool.worker,
      size: pool.size,
      max_overflow: pool.overflow
    ]

    children = [
      :poolboy.child_spec(pool.name, poolboy_config, {connection, listener}),
      worker(SmartWebsocketClient.Manager, [{self(), pool.name}, [name: SWCManager]])
    ]

    supervise(children, [strategy: :one_for_one])
  end

  @doc """
  Connect to the websocket server.

  This function allows the user to specify an optional pool. If no pool is
  specified, only one connection will be created. It still uses the pool
  transaction mechanism under the hood, since a single connection pool
  (with no overflow) will is created.

  ## Example

      SmartWebsocketClient.connect(connection, listener)
      SmartWebsocketClient.connect(connection, listener, pool)
  """
  def connect(connection_config, listener, pool_config \\ @single_connection_pool) do
    start_link({connection_config, listener, pool_config})
  end


  @doc """
  Disconnect from the websocket server.

  Calling `disconnect/0` will stop all pool workers and kill the supervisor.
  Currently, it doesn't disconnect websockets gracefully. That's TODO.

  ## Example

      SmartWebsocketClient.disconnect()
  """
  def disconnect() do
    manager_data = GenServer.call(SWCManager, :fetch)
    :poolboy.stop(manager_data.pool_name)
    Supervisor.stop(manager_data.supervisor_pid)
  end

  @doc """
  Send a message.

  You can send either a string message or a map, which will be encoded to JSON.
  Throws an `ArgumentError` if an invalid message is passed as argument.

  The client will transparently handle the pool for you. Websocket connections
  are reserved at a FIFO basis.

  ## Examples

      SmartWebsocketClient.send("MyStringMessage")
      SmartWebsocketClient.send(%{my: "map"})
  """
  def send(msg) do
    msg
    |> validate()
    |> transaction_send()
  end

  defp validate(msg) when is_binary(msg),
    do: msg
  defp validate(msg) when is_map(msg),
    do: Poison.encode!(msg)
  defp validate(_),
    do: raise ArgumentError, "invalid message"

  # This function is responsible for handling the pool. A transaction in poolboy
  # world means I'm reserving a worker for myself and no one else can use it while
  # I don't finish my stuff. If the worker dies while in a transaction, poolboy
  # takes care of it.
  defp transaction_send(msg) do
    :poolboy.transaction(:websocket_pool, fn(worker) ->
      GenServer.cast(worker, {:send, msg})
    end)
  end
end
