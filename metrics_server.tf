module "metrics_server" {
  source = "./addons/metrics-server"

  enabled      = var.metrics_server_enabled
  helm_version = var.metrics_server_helm_version
  replicas     = var.metrics_server_replicas
}
