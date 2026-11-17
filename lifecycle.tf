resource "terraform_data" "upgrade_kubernetes" {
  triggers_replace = [
    var.kubernetes_version
  ]

  provisioner "local-exec" {
    interpreter = [var.bash_interpreter, "-c"]

    command = templatefile("${path.module}/templates/talos_kubernetes_version_upgrade.sh.tftpl", {
      endpoint           = local.bootstrap_node
      kubernetes_version = trimprefix(var.kubernetes_version, "v")
    })

    environment = {
      TALOSCONFIG_CONTENT = data.talos_client_configuration.this.talos_config
      KUBECONFIG_CONTENT  = talos_cluster_kubeconfig.this.kubeconfig_raw
    }

    quiet = true
  }

  depends_on = [
    talos_machine_configuration_apply.this,
    talos_machine_bootstrap.this,
    talos_cluster_kubeconfig.this,
    terraform_data.upgrade_talos
  ]
  provisioner "local-exec" {
    interpreter = [var.bash_interpreter, "-c"]
    command     = "if [ -f kubernetes-upgrade.log ]; then cat kubernetes-upgrade.log && rm -f kubernetes-upgrade.log; fi"
  }
}

resource "terraform_data" "kubernetes_bootstrap_version" {
  input = var.kubernetes_version

  lifecycle {
    ignore_changes = [input]
  }
}

resource "terraform_data" "upgrade_talos" {
  triggers_replace = [
    var.talos_version
  ]

  provisioner "local-exec" {
    interpreter = [var.bash_interpreter, "-c"]

    command = templatefile("${path.module}/templates/talos_os_version_upgrade.sh.tftpl", {
      endpoints         = join(",", [for node in values(local.control_plane_nodes) : split("/", node.ip_address)[0]])
      talos_version     = var.talos_version
      control_plane_ips = join(" ", [for node in values(local.control_plane_nodes) : split("/", node.ip_address)[0]])
      worker_ips        = join(" ", [for node in values(local.worker_nodes) : split("/", node.ip_address)[0]])
    })

    environment = {
      TALOSCONFIG_CONTENT = data.talos_client_configuration.this.talos_config
      KUBECONFIG_CONTENT  = talos_cluster_kubeconfig.this.kubeconfig_raw
    }

    quiet = true
  }

  depends_on = [
    talos_machine_configuration_apply.this,
    talos_machine_bootstrap.this,
    talos_cluster_kubeconfig.this
  ]
  provisioner "local-exec" {
    interpreter = [var.bash_interpreter, "-c"]
    command     = "if [ -f talos-os-upgrade.log ]; then cat talos-os-upgrade.log && rm -f talos-os-upgrade.log; fi"
  }
}
