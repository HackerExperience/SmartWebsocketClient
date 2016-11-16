defmodule SmartWebsocketClient.Worker do
  @moduledoc false
  use GenServer
  alias SmartWebsocketClient.Connection


  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  @doc false
  def init({connection, listener}) do
    # Create socket
    socket = create_socket(connection)

    # Launch this socket's listener
    {:ok, pid} = GenServer.start_link(listener, socket, [])
    listener.listen(pid)

    {:ok, socket}
  end

  @doc false
  def handle_cast({:send, msg}, socket) do
    socket
    |> SmartWebsocketClient.Socket.send(msg)
    {:noreply, socket}
  end

  defp create_socket(%Connection{host: host, port: port, path: path}) do
    SmartWebsocketClient.Socket.connect(host, port, path)
  end
end
