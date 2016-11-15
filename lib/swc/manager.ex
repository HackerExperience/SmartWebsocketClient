defmodule SimpleWebsocketClient.Manager do
  use GenServer

  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init({pid, pool_name}) do
    {:ok, %{supervisor_pid: pid, pool_name: pool_name}}
  end

  def handle_call({:fetch},  _from, state) do
    {:reply, state, state}
  end
end
