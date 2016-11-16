defmodule SmartWebsocketClient.Test.Helper.ListenerLogger do
  use SmartWebsocketClient.Listener
  import Logger

  def on_receive(msg) do
    Logger.debug "Received: #{msg}"
  end
end
