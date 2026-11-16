data "helm_template" "this" {
  count = var.enabled ? 1 : 0

  name       = var.name
  namespace  = var.namespace
  repository = var.repository
  chart      = var.chart
  version    = var.helm_version

  values = [
    yamlencode({
      replicas = var.replicas
    }),
    yamlencode(var.helm_values)
  ]
}
