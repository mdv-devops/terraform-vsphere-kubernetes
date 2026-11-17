resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version

  lifecycle {
    ignore_changes = [
      talos_version
    ]
  }
}

resource "talos_machine_configuration_apply" "this" {
  for_each = local.nodes

  node                        = split("/", each.value.ip_address)[0]
  endpoint                    = split("/", each.value.ip_address)[0]
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration
  apply_mode                  = var.talos_machine_configuration_apply_mode
  on_destroy = {
    reset    = true
    graceful = true
    reboot   = false
  }
  depends_on = [vsphere_virtual_machine.this]
}

resource "talos_machine_bootstrap" "this" {
  node                 = local.bootstrap_node
  endpoint             = local.bootstrap_node
  client_configuration = talos_machine_secrets.this.client_configuration

  depends_on = [talos_machine_configuration_apply.this]
}

resource "talos_cluster_kubeconfig" "this" {
  node                 = local.bootstrap_node
  endpoint             = local.bootstrap_node
  client_configuration = talos_machine_secrets.this.client_configuration

  depends_on = [talos_machine_bootstrap.this]
}
