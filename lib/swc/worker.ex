defmodule SimpleWebsocketClient.Worker do
  use GenServer
  alias SimpleWebsocketClient.ConnectionConfig

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

  def handle_call({:send, msg}, _from, socket) do
    socket
    |> SimpleWebsocketClient.Socket.send(msg) 
    {:reply, nil, socket}
  end

  defp create_socket(%ConnectionConfig{host: host, port: port, path: path}) do
    SimpleWebsocketClient.Socket.connect(host, port, path)
  end
end
