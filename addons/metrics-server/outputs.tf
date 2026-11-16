output "config_patches" {
  description = "Talos KubeInlineManifestConfig patches for Metrics Server"

  value = var.enabled ? [
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "KubeInlineManifestConfig"
      name       = var.name
      manifest   = data.helm_template.this[0].manifest
    })
  ] : []
}
