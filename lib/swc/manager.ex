defmodule SmartWebsocketClient.Manager do
  @moduledoc false
  @docp """
  This module is used to keep some state of the SWC. Notably, we need its
  supervisor's pid and the pool name.

  Currently it's only used on disconnection, which needs to know both the
  pool name (to stop the workers) and the supervisor pid (to kill it).
  """
  use GenServer

  def start_link(args, opts \\ []) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init({pid, pool_name}) do
    {:ok, %{supervisor_pid: pid, pool_name: pool_name}}
  end

  def handle_call(:fetch,  _from, state) do
    {:reply, state, state}
  end
end
