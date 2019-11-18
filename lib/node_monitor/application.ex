defmodule NodeMonitor.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    NodeMonitor.Supervisor.start_link()
  end
end
