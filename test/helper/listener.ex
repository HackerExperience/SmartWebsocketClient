defmodule SmartWebsocketClient.Test.Helper.ListenerLogger do
  use SmartWebsocketClient.Listener
  require Logger

  def on_receive(msg) do
    Logger.flush()
    Logger.debug "Received: #{msg}"
  end
end
