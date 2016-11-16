defmodule SmartWebsocketClient.Socket do
  @moduledoc false
  @docp """
  Generic websocket interface.

  This module is a simple interface to the lower level socket library we use.
  If, in the future, we want to use a different library, we should need to
  modify this module only.

  This module is used internally.
  """

  def connect(host, port, path) do
    Socket.Web.connect!(host, port, path: path)
  end

  def recv(socket) do
    socket
    |> Socket.Web.recv!
  end

  def send(socket, :pong) do
    socket
    |> Socket.Web.send!({:pong, ""})
  end

  def send(socket, msg) do
    socket
    |> Socket.Web.send!({:text, msg})
  end
end
