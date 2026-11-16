output "nodes" {
  description = "Created VMs and statically configured node addresses"
  value = {
    for name, vm in vsphere_virtual_machine.this : name => {
      name       = vm.name
      id         = vm.id
      uuid       = vm.uuid
      role       = local.nodes[name].role
      pool       = local.nodes[name].pool
      ip_address = split("/", local.nodes[name].ip_address)[0]
    }
  }
}

output "control_plane_nodes" {
  value = { for name, node in local.control_plane_nodes : name => split("/", node.ip_address)[0] }
}

output "worker_nodes" {
  value = { for name, node in local.worker_nodes : name => split("/", node.ip_address)[0] }
}

output "cluster_endpoint" {
  value = var.cluster_endpoint
}

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}
