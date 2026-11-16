variable "enabled" {
  description = "Enable Metrics Server"
  type        = bool
  default     = true
}

variable "helm_version" {
  description = "Metrics Server Helm chart version"
  type        = string
  default     = "3.14.0"
}

variable "replicas" {
  description = "Number of Metrics Server replicas"
  type        = number
  default     = 2

  validation {
    condition     = var.replicas >= 1
    error_message = "Replicas must be at least 1."
  }
}

variable "name" {
  description = "The name of Metrics Server helm release"
  type        = string
  default     = "metrics-server"
}

variable "namespace" {
  description = "Metrics Server Helm resease namespace"
  type        = string
  default     = "kube-system"
}

variable "repository" {
  description = "Metrics Server Helm chart repo"
  type        = string
  default     = "https://kubernetes-sigs.github.io/metrics-server/"
}

variable "chart" {
  description = "Metrics Server Helm chart name"
  type        = string
  default     = "metrics-server"
}

variable "helm_values" {
  description = "Additional Metrics Server Helm values"
  type        = any
  default = {
    args = [
      "--kubelet-insecure-tls"
    ]

    affinity = {
      podAntiAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = [
          {
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name" = "metrics-server"
              }
            }
            topologyKey = "kubernetes.io/hostname"
          }
        ]
      }
    }
  }
}
