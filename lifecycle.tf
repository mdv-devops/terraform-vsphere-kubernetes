resource "terraform_data" "manifest_revision" {
  input = sha256(jsonencode(module.metrics_server.config_patches))
}

resource "terraform_data" "synchronize_manifests" {
  triggers_replace = [
    sha256(jsonencode(module.metrics_server.config_patches))
  ]

  provisioner "local-exec" {
    interpreter = [var.bash_interpreter, "-c"]

    command = templatefile("${path.module}/templates/talos_upgrade_k8s.sh.tftpl", {
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
    talos_cluster_kubeconfig.this
  ]
}

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
    terraform_data.synchronize_manifests
  ]
}
