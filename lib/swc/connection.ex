defmodule SmartWebsocketClient.Connection do
  @moduledoc """
  `SmartWebsocketClient.Connection` is a struct with the data required to establish
  a connection to a websocket server.
  """
  defstruct host: "127.0.0.1", port: 80, path: "/"
end
