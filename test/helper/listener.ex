defmodule SimpleWebsocketClient.Test.Helper.ListenerLogger do
  use SimpleWebsocketClient.Listener
  import Logger

  def on_receive(msg) do
    Logger.debug "Received: #{msg}"
  end
end
