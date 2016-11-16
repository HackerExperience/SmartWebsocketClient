defmodule SmartWebsocketClient.Test.Helper.Server do
  @behaviour :cowboy_websocket_handler
  require Logger

  def run(port) do
    routes = [
      {"/", __MODULE__, []}
    ]

    dispatch = :cowboy_router.compile([{:_, routes}])
    opts = [port: port]
    env = [dispatch: dispatch]

    {:ok, _} = :cowboy.start_http(:http, 100, opts, [env: env])
  end

  def init(_, _req, _opts),
    do: {:upgrade, :protocol, :cowboy_websocket}

  def websocket_init(_type, req, _opts),
    do: {:ok, req, %{}, :infinity}

  def websocket_handle({:text, "send_me_ping"}, req, state) do
    {:reply, :ping, req, state}
  end

  def websocket_handle({:pong, _}, req, state) do
    Logger.flush
    Logger.debug "server received pong"
    {:reply, {:text, "pong ok"}, req, state}
  end

  def websocket_handle({:text, message}, req, state) do
    Logger.flush
    Logger.debug message
    {:reply, {:text, message}, req, state}
  end

  def websocket_info(message, req, state) do
    {:reply, {:text, message}, req, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    :ok # TODO: match termination reason
  end
end
