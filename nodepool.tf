locals {
  control_plane_nodes = merge({}, [for pool in var.control_plane_nodepools : {
    for node_name, spec in pool.nodes : "${pool.name}-${node_name}" => merge(spec, {
      role                   = "controlplane"
      pool                   = pool.name
      cpu_hot_add_enabled    = pool.cpu_hot_add_enabled
      memory_hot_add_enabled = pool.memory_hot_add_enabled
    })
  }]...)

  worker_nodes = merge({}, [for pool in var.worker_nodepools : {
    for node_name, spec in pool.nodes : "${pool.name}-${node_name}" => merge(spec, {
      role                   = "worker"
      pool                   = pool.name
      cpu_hot_add_enabled    = pool.cpu_hot_add_enabled
      memory_hot_add_enabled = pool.memory_hot_add_enabled
    })
  }]...)

  nodes          = merge(local.control_plane_nodes, local.worker_nodes)
  bootstrap_node = split("/", local.control_plane_nodes[var.bootstrap_node_name].ip_address)[0]
}
