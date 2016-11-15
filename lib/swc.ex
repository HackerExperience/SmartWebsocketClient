defmodule SimpleWebsocketClient do
  use Supervisor
  import Supervisor.Spec
  alias SimpleWebsocketClient.Pool

  @single_connection_pool %SimpleWebsocketClient.Pool{size: 1, overflow: 0}

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, [])
  end

  def init({connection, pool, listener}) do
    poolboy_config = [
      name: {:local, pool.name},
      worker_module: pool.worker,
      size: pool.size,
      max_overflow: pool.overflow
    ]

    children = [
      :poolboy.child_spec(pool.name, poolboy_config, {connection, listener}),
      worker(SimpleWebsocketClient.Manager, [{self(), pool.name}, [name: SWCManager]])
    ]

    supervise(children, [strategy: :one_for_one])
  end

  def connect(connection_config, pool_config, listener) do
    start_link({connection_config, pool_config, listener})
  end

  def connect(connection_config, listener) do
    start_link({connection_config, @single_connection_pool, listener})
  end

  def disconnect() do
    manager_data = GenServer.call(SWCManager, {:fetch})
    :poolboy.stop(manager_data[:pool_name])
    Supervisor.stop(manager_data[:supervisor_pid])
  end

  def send(msg) do
    msg
    |> validate()
    |> transaction_send()
  end

  def validate(msg) when is_binary(msg),
    do: msg
  def validate(msg) when is_map(msg),
    do: Poison.encode!(msg)
  def validate(msg),
    do: raise RuntimeError, "invalid message"

  defp transaction_send(msg) do
    :poolboy.transaction(:websocket_pool, fn(worker) ->
      GenServer.call(worker, {:send, msg})
    end)
  end
end
