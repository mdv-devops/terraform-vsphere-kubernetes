resource "vsphere_virtual_machine" "this" {
  for_each = local.nodes

  name             = each.key
  folder           = var.vsphere_folder
  resource_pool_id = data.vsphere_resource_pool.this.id
  datastore_id     = data.vsphere_datastore.this.id

  num_cpus = each.value.cpu
  memory   = each.value.memory_mb

  guest_id               = data.vsphere_virtual_machine.this.guest_id
  firmware               = data.vsphere_virtual_machine.this.firmware
  scsi_type              = data.vsphere_virtual_machine.this.scsi_type
  enable_disk_uuid       = true
  cpu_hot_add_enabled    = each.value.cpu_hot_add_enabled
  memory_hot_add_enabled = each.value.memory_hot_add_enabled

  network_interface {
    network_id   = data.vsphere_network.this.id
    adapter_type = "vmxnet3"
  }

  disk {
    label            = "disk0"
    size             = each.value.disk_gb
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.this.id
  }

  vapp {
    properties = {
      "talos.config" = base64encode(data.talos_machine_configuration.this[each.key].machine_configuration)
    }
  }
  lifecycle {
    ignore_changes = [
      vapp[0].properties["talos.config"]
    ]
  }
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0
}
