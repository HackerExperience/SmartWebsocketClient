defmodule SimpleWebsocketClient.Listener do
  @callback on_receive(msg :: any) :: any

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour SimpleWebsocketClient.Listener

      @doc false
      def start_link do
        GenServer.start_link(__MODULE__, [], [])
      end

      @doc false
      def init(socket) do
        IO.puts "initing"
        IO.inspect socket
        {:ok, socket}
      end

      @doc false
      def wait_for_message(socket) do
        socket
        |> SimpleWebsocketClient.Socket.recv
        |> case do
          {:text, data} ->
            on_receive(data)
            wait_for_message(socket)
          {:ping, _} ->
            handle_ping(socket)
          unknown ->
            handle_unknown(socket)
          end
      end

      @doc false
      def handle_cast(:listen, socket) do
        wait_for_message(socket)
        {:noreply, socket}
      end

      @doc false
      def listen(pid) do
       GenServer.cast(pid, :listen)
      end

      @doc false
      def handle_ping(socket) do
        socket
        |> SimpleWebsocketClient.Socket.send(:pong)
        wait_for_message(socket)
      end

      @doc false
      def handle_unknown(socket) do
        wait_for_message(socket)
      end

      defoverridable [init: 1, handle_cast: 2, wait_for_message: 1, listen: 1,
                      handle_ping: 1, handle_unknown: 1]

    end
  end
end