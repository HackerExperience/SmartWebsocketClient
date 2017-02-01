defmodule SmartWebsocketClient.Listener do

  @moduledoc """
  Behaviour to act on received messages.

  ## Example

      defmodule MyListener do
        use SmartWebsocketClient.Listener

        def on_receive(msg) do
          IO.inspect msg
        end
      end

  """

  @doc """
  Callback function that is called every time a message is received.

  The received message is passed as an argument. You are not expected to
  return anything in special.

  You are required to implement this callback.

  ## Example:

      def on_receive(msg) do
        IO.inspect msg
      end
  """
  @callback on_receive(msg :: any) :: any

  @doc """
  Blocking infinite loop that waits for received messages and dispatches to the
  relevant handler when a message is received.

  The default implementation dispatches ping messages to `handle_ping/1`, text
  messages to `on_receive/1` and "others" to `handle_unknown/1`.

  You don't need to override/implement this callback unless you want to extend
  the default behaviour.

  ## Default implementation

      def wait_message(socket) do
        socket
        |> SmartWebsocketClient.socket.recv
        |> case do
          {:text, data} ->
            on_receive(data)
          {:ping, _} ->
            handle_ping(socket)
          _ ->
            handle_unknown(socket)
        end
        wait_message(socket)
      end
  """
  @callback wait_message(socket :: any) :: any


  @doc """
  What to do when a ping message is received.

  You don't need to override/implement this callback unless you want to extend
  the default behaviour.

  ## Default implementation

      def handle_ping(socket) do
        socket
        |> SmartWebsocketClient.Socket.send(:pong)
      end

  """
  @callback handle_ping(socket :: any) :: any


  @doc """
  What to do when an unknown message is received.

  This is the type of function that should never be called...

  You don't need to override/implement this callback unless you want to extend
  the default behaviour.

  ### Default implementation

      def handle_unknown(socket) do
        :ok
      end
  """
  @callback handle_unknown(socket :: any) :: any

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour SmartWebsocketClient.Listener

      @doc false
      def start_link do
        GenServer.start_link(__MODULE__, [], [])
      end

      @doc false
      def init(socket) do
        {:ok, socket}
      end

      @doc false
      def wait_message(socket) do
        socket
        |> SmartWebsocketClient.Socket.recv
        |> case do
          {:text, data} ->
            on_receive(data)
          {:ping, _} ->
            handle_ping(socket)
          _ ->
            handle_unknown(socket)
           end
        wait_message(socket)
      end

      @doc false
      def handle_cast(:listen, socket) do
        wait_message(socket)
        {:noreply, socket}
      end

      @doc false
      def listen(pid) do
       GenServer.cast(pid, :listen)
      end

      @doc false
      def handle_ping(socket) do
        socket
        |> SmartWebsocketClient.Socket.send(:pong)
      end

      @doc false
      def handle_unknown(socket) do
        :ok
      end

      @doc false
      def terminate(reason, state) do
        :ok
      end

      defoverridable [init: 1, handle_cast: 2, wait_message: 1, listen: 1,
                      handle_ping: 1, handle_unknown: 1, terminate: 2]

    end
  end
end
