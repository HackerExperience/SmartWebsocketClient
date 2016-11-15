defmodule SimpleWebsocketClient.Worker do
  use GenServer
  alias SimpleWebsocketClient.Connection

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  def init({connection, listener}) do
    # Create socket
    socket = create_socket(connection)

    # Launch this socket's listener
    {:ok, pid} = GenServer.start_link(listener, socket, [])
    listener.listen(pid)

    {:ok, socket}
  end

  def handle_cast({:send, msg}, socket) do
    socket
    |> SimpleWebsocketClient.Socket.send(msg)
    {:noreply, socket}
  end

  defp create_socket(%Connection{host: host, port: port, path: path}) do
    SimpleWebsocketClient.Socket.connect(host, port, path)
  end
end
