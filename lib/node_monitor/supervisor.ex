defmodule NodeMonitor.Supervisor do
  @moduledoc false

  use Supervisor

  @node_monitor %{
    id: NodeMonitor.Monitor,
    start: {NodeMonitor.Monitor, :start_link, []},
    type: :worker
  }

  @children [
    @node_monitor
  ]

  @sup_flags [
    strategy: :one_for_all,
    max_restarts: 5,
    max_seconds: 10
  ]

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    Supervisor.init(@children, @sup_flags)
  end
end
