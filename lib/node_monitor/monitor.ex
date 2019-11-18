defmodule NodeMonitor.Monitor do
  @moduledoc false

  use GenServer

  import Logger

  alias __MODULE__, as: State

  defstruct(
    nodes: MapSet.new(),
    subscribers: MapSet.new(),
    timer_ref: nil
  )

  # API functions

  @spec register(Node.t()) :: :ok | {:error, term} | none
  def register(node) when node != node(),
    do: GenServer.call(__MODULE__, {:register, node})

  @spec register(Node.t()) :: :ok | none
  def register(_node),
    do: {:error, :register_self}

  @spec unregister(Node.t()) :: :ok | none
  def unregister(node),
    do: GenServer.call(__MODULE__, {:unregister, node})

  @spec subscribe() :: :ok
  def subscribe,
    do: GenServer.cast(__MODULE__, {:subscribe, self()})

  @spec start_link() :: GenServer.start_link()
  def start_link,
    do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  # GenServer callback functions

  @impl GenServer
  def init(_args) do
    :ok = info("node monitor started on #{Node.self()}")
    {:ok, %State{}}
  end

  @impl GenServer
  def handle_call({:register, node}, from, state) do
    if MapSet.member?(state.nodes, node) do
      # Already connected
      {:reply, :ok, state}
    else
      :ok = debug("send connect request to #{node}")
      :ok = send_connect_request(node, from)
      {:noreply, state}
    end
  end

  @impl GenServer
  def handle_call({:unregister, node}, from, state) do
    if MapSet.member?(state.nodes, node) do
      :ok = debug("unregistering #{node}")
      :ok = send_disconnect_request(node, from)
      {:noreply, state}
    else
      # Already disconnected
      {:reply, :ok, state}
    end
  end

  @impl GenServer
  def handle_cast({:subscribe, pid}, state) do
    {:noreply, %{state | subscribers: MapSet.put(state.subscribers, pid)}}
  end

  @impl GenServer
  def handle_cast(%{type: :connect_request, sender: node} = request, state) do
    :ok = info("received connect request from #{node}")
    :ok = :aten.register(node)
    :ok = send_connect_reply(request)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(%{type: :connect_reply, sender: node} = reply, state) do
    :ok = info("received connect reply from #{node}")
    :ok = GenServer.reply(reply.client, :ok)
    :ok = :aten.register(node)
    _ = Process.cancel_timer(reply.tref)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(%{type: :disconnect_request, sender: node} = request, state) do
    :ok = info("received disconnect request from #{node}")
    :ok = :aten.unregister(node)
    :ok = send_disconnect_reply(request)
    {:noreply, %{state | nodes: MapSet.delete(state.nodes, node)}}
  end

  @impl GenServer
  def handle_cast(%{type: :disconnect_reply, sender: node} = reply, state) do
    :ok = info("received disconnect reply from #{node}")
    :ok = GenServer.reply(reply.client, :ok)
    :ok = :aten.unregister(node)
    _ = Process.cancel_timer(reply.tref)
    _ = Node.disconnect(node)
    {:noreply, %{state | nodes: MapSet.delete(state.nodes, node)}}
  end

  @impl GenServer
  def handle_info({:timeout, {node, from}}, state) do
    :ok = warn("connect failed node: #{node}")
    :ok = GenServer.reply(from, {:error, :timeout})
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:node_event, node, :down} = event, state) do
    if is_connected?(node) do
      {:noreply, state}
    else
      :ok = warn("node: #{node} down detected")
      :ok = Enum.each(state.subscribers, &Process.send(&1, event, []))
      {:noreply, %{state | nodes: MapSet.delete(state.nodes, node)}}
    end
  end

  @impl GenServer
  def handle_info({:node_event, node, :up} = event, state) do
    :ok = info("node: #{node} up detected")
    :ok = Enum.each(state.subscribers, &Process.send(&1, event, []))
    {:noreply, %{state | nodes: MapSet.put(state.nodes, node)}}
  end

  @impl GenServer
  def handle_info(_info, state) do
    {:noreply, state}
  end

  # private functions

  @spec send_connect_request(Node.t(), GenServer.from()) :: :ok
  defp send_connect_request(node, from) do
    cast(
      node,
      %{
        type: :connect_request,
        sender: Node.self(),
        client: from,
        tref: make_timer({:timeout, {node, from}}, 3000)
      }
    )
  end

  @spec send_connect_reply(request :: map) :: :ok
  defp send_connect_reply(request) do
    cast(
      request.sender,
      %{
        type: :connect_reply,
        sender: Node.self(),
        client: request.client,
        tref: request.tref
      }
    )
  end

  @spec send_disconnect_request(Node.t(), GenServer.from()) :: :ok
  defp send_disconnect_request(node, from) do
    cast(
      node,
      %{
        type: :disconnect_request,
        sender: Node.self(),
        client: from,
        tref: make_timer({:timeout, {node, from}}, 3000)
      }
    )
  end

  @spec send_disconnect_reply(request :: map) :: :ok
  defp send_disconnect_reply(request) do
    cast(
      request.sender,
      %{
        type: :disconnect_reply,
        sender: Node.self(),
        client: request.client,
        tref: request.tref
      }
    )
  end

  @spec is_connected?(Node.t()) :: boolean
  defp is_connected?(node),
    do: Enum.member?(Node.list(), node)

  @spec make_timer(map, non_neg_integer) :: reference
  defp make_timer(msg, timeout),
    do: Process.send_after(__MODULE__, msg, timeout)

  @spec cast(Node.t(), map) :: :ok
  defp cast(node, message),
    do: GenServer.cast({__MODULE__, node}, message)
end
