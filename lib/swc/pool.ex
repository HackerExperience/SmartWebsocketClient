defmodule SmartWebsocketClient.Pool do

  @moduledoc """
  `SmartWebsocketClient.Pool` is a struct with the data required to create a
  pool of websocket connections.
  """
  @default_name :websocket_pool

  defstruct \
    size: 4,
    overflow: 2,
    name: @default_name,
    worker: SmartWebsocketClient.Worker

  @doc """
  Return the default name used by the websocket pool.

  Useful for tests and stuff...
  """
  def default_name do
    @default_name
  end
end
