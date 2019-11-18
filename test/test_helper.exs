:net_kernel.start([:"node3@127.0.0.1"])
# start the current node as a manager
:ok = LocalCluster.start()
ExUnit.configure(seed: 0)
ExUnit.start()
