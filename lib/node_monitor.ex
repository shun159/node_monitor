defmodule NodeMonitor do
  @moduledoc """
  Node Monitor
  """

  @spec register(Node.t()) :: :ok | {:error, term}
  def register(node),
    do: NodeMonitor.Monitor.register(node)

  @spec unregister(Node.t()) :: :ok | {:error, term}
  def unregister(node),
    do: NodeMonitor.Monitor.unregister(node)

  @spec subscribe() :: :ok
  def subscribe,
    do: NodeMonitor.Monitor.subscribe()
end
