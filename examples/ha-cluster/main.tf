module "kubernetes" {
  source = "../.."

  providers = {
    vsphere = vsphere
    talos   = talos
  }

  bash_interpreter = var.bash_interpreter

  vsphere_datacenter    = var.vsphere_datacenter
  vsphere_datastore     = var.vsphere_datastore
  vsphere_network       = var.vsphere_network
  vsphere_resource_pool = var.vsphere_resource_pool
  vsphere_folder        = var.vsphere_folder
  talos_template_name   = var.talos_template_name

  cluster_name        = var.cluster_name
  control_plane_vip   = var.control_plane_vip
  cluster_endpoint    = "https://${var.control_plane_vip}:6443"
  talos_version       = var.talos_version
  kubernetes_version  = var.kubernetes_version
  ntp_servers         = var.ntp_servers
  bootstrap_node_name = var.bootstrap_node_name

  control_plane_nodepools = [{
    name                   = "talos"
    cpu_hot_add_enabled    = true
    memory_hot_add_enabled = true

    nodes = {
      "control-plane-1" = {
        cpu        = 3
        memory_mb  = 4096
        disk_gb    = 40
        ip_address = "192.168.43.10/24"
        gateway    = "192.168.43.2"
        dns        = ["192.168.55.10"]
      },
      "control-plane-2" = {
        cpu        = 2
        memory_mb  = 4096
        disk_gb    = 40
        ip_address = "192.168.43.11/24"
        gateway    = "192.168.43.2"
        dns        = ["192.168.55.10"]
      },
      "control-plane-3" = {
        cpu        = 2
        memory_mb  = 4096
        disk_gb    = 40
        ip_address = "192.168.43.12/24"
        gateway    = "192.168.43.2"
        dns        = ["192.168.55.10"]
      }
    }
  }]

  worker_nodepools = [{
    name                   = "talos"
    cpu_hot_add_enabled    = true
    memory_hot_add_enabled = true
    nodes = {
      "worker-1" = {
        cpu        = 4
        memory_mb  = 4096
        disk_gb    = 40
        ip_address = "192.168.43.13/24"
        gateway    = "192.168.43.2"
        dns        = ["192.168.55.10"]
      },
      "worker-2" = {
        cpu        = 4
        memory_mb  = 4096
        disk_gb    = 40
        ip_address = "192.168.43.14/24"
        gateway    = "192.168.43.2"
        dns        = ["192.168.55.10"]
      },
      "worker-3" = {
        cpu        = 4
        memory_mb  = 4096
        disk_gb    = 40
        ip_address = "192.168.43.15/24"
        gateway    = "192.168.43.2"
        dns        = ["192.168.55.10"]
      }
    }
  }]
}
