defmodule FaktoryWorker.Worker.ShutdownManager do
  @moduledoc false

  use GenServer

  alias FaktoryWorker.Worker.Server

  @spec start_link(opts :: keyword()) :: Supervisor.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: name_from_opts(opts))
  end

  @spec child_spec(opts :: keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: name_from_opts(opts),
      start: {__MODULE__, :start_link, [opts]},
      type: :worker
    }
  end

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    {:ok, opts}
  end

  @impl true
  def terminate(_reason, state) do
    state
    |> FaktoryWorker.Worker.Pool.format_worker_pool_name()
    |> Supervisor.which_children()
    |> Enum.each(&shutdown_worker/1)
  end

  defp shutdown_worker({_, worker_pid, _, _}) do
    Server.disable_fetch(worker_pid)
  end

  defp name_from_opts(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    :"#{name}_shutdown_manager"
  end
end