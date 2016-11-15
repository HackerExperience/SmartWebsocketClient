defmodule SimpleWebsocketClient.Socket do

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
