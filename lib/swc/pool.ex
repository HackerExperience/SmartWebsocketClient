defmodule SmartWebsocketClient.Pool do

  @default_name :websocket_pool

  defstruct \
    size: 4,
    overflow: 2,
    name: @default_name,
    worker: SmartWebsocketClient.Worker

  def default_name do
    @default_name
  end
end
