defmodule SmartWebsocketClient.Test.Helper.Server do
  @behaviour :cowboy_websocket_handler
  import Logger

  @doc ~S"""
    Starts the router, usually called from a supervisor.
    Should return `{:ok, pid}` on normal conditions.
  """
  def run(port) do
    routes = [
      {"/", __MODULE__, []}
    ]

    dispatch = :cowboy_router.compile([{:_, routes}])
    opts = [port: port]
    env = [dispatch: dispatch]

    {:ok, _} = :cowboy.start_http(:http, 100, opts, [env: env])
  end

  # cowboy callbacks

  # setup cowboy connection type
  @doc ~S"""
  Upgrades the protocol to websocket.
  """
  def init(_, _req, _opts), do: {:upgrade, :protocol, :cowboy_websocket}

  # setup websocket connection
  @doc ~S"""
  Negotiates the protocol with the client, also sets the connection timeout.
  """
  def websocket_init(_type, req, _opts), do: {:ok, req, %{}, :infinity}

  @doc ~S"""
  Ping request handler, replies with pong.
  """
  def websocket_handle({:text, "ping"}, req, state) do
    {:reply, {:text, "pong"}, req, state}
  end

  @doc ~S"""
  Request handler, deals with JSON message propagation and response.
  """
  def websocket_handle({:text, message}, req, state) do
    Logger.debug message
    {:reply, {:text, message}, req, state}
  end

  @doc ~S"""
  Reply handler, formats elixir messages into cowboy messages.
  """
  def websocket_info(message, req, state) do
    {:reply, {:text, message}, req, state}
  end

  @doc ~S"""
  Termination handler, should perform state cleanup, the connection is closed
  after this call.
  """
  def websocket_terminate(_reason, _req, _state) do
    :ok # TODO: match termination reason
  end
end
