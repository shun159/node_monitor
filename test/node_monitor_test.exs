defmodule NodeMonitorTest do
  use ExUnit.Case, async: false

  setup_all do
    nodes = LocalCluster.start_nodes("node", 2)
    {:ok, nodes: nodes}
  end

  describe "NodeMonitor.register/1" do
    test "with an alive node" do
      :ok = NodeMonitor.subscribe()
      :ok = NodeMonitor.register(:"node1@127.0.0.1")
      assert_receive {:node_event, :"node1@127.0.0.1", :up}, 1000
      assert Enum.member?(Node.list(), :"node1@127.0.0.1")
    end

    test "with a dead node" do
      :ok = NodeMonitor.subscribe()
      {:error, :timeout} = NodeMonitor.register(:"node4@127.0.0.1")
    end

    test "with a self" do
      :ok = NodeMonitor.subscribe()
      {:error, :register_self} = NodeMonitor.register(Node.self())
    end
  end

  describe "NodeMonitor.unregister/1" do
    test "with an alive node" do
      :ok = NodeMonitor.subscribe()
      :ok = NodeMonitor.unregister(:"node1@127.0.0.1")
      refute Enum.member?(Node.list(), :"node1@127.0.0.1")
    end

    test "with a dead node" do
      :ok = NodeMonitor.subscribe()
      :ok = NodeMonitor.unregister(:"node4@127.0.0.1")
    end
  end

  describe "NodeMonitor" do
    test "when occur node down event" do
      :ok = NodeMonitor.subscribe()
      :ok = NodeMonitor.register(:"node1@127.0.0.1")
      :ok = LocalCluster.stop_nodes([:"node1@127.0.0.1"])
      assert_receive {:node_event, :"node1@127.0.0.1", :down}, 1000
    end
  end
end
