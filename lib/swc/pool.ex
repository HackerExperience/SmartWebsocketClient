defmodule SimpleWebsocketClient.Pool do

  @default_name :websocket_pool

  defstruct \
    size: 4,
    overflow: 2,
    name: @default_name,
    worker: SimpleWebsocketClient.Worker

  def default_name do
    @default_name
  end
end
