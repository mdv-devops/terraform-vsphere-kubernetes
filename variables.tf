#=============== Vsphere ===============

variable "vsphere_datacenter" {
  type = string
}
variable "vsphere_datastore" {
  type = string
}
variable "vsphere_network" {
  type = string
}
variable "vsphere_resource_pool" {
  type = string
}
variable "vsphere_folder" {
  type = string
}
#=============== Cluster ===============

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "v1.37.0"
}
variable "talos_template_name" {
  description = "Existing Talos vSphere VM template name"
  type        = string
}
variable "cluster_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.cluster_name))
    error_message = "cluster_name must be a lowercase DNS-style name of at least two characters."
  }
}
variable "cluster_endpoint" {
  description = "Kubernetes API URL, e.g. https://192.168.43.10:6443"
  type        = string
}
variable "talos_version" {
  type    = string
  default = "v1.14.6"
}
variable "talos_network_interface" {
  type    = string
  default = "eth0"
}
variable "ntp_servers" {
  type = list(string)
}
variable "talos_machine_configuration_apply_mode" {
  type    = string
  default = "no_reboot"
  validation {
    condition     = contains(["auto", "no_reboot", "staged"], var.talos_machine_configuration_apply_mode)
    error_message = "Apply mode must be auto, no_reboot, or staged."
  }
}
variable "bootstrap_node_name" {
  description = "Full control-plane node name (pool name + hyphen + node key); keep stable after bootstrap"
  type        = string
}
variable "control_plane_vip" {
  description = "Virtual IP address for the Kubernetes API"
  type        = string
  default     = null
}
variable "control_plane_nodepools" {
  type = list(object({
    name                   = string
    cpu_hot_add_enabled    = optional(bool, false)
    memory_hot_add_enabled = optional(bool, false)
    nodes = map(object({
      cpu        = number
      memory_mb  = number
      disk_gb    = number
      ip_address = string
      gateway    = string
      dns        = list(string)
    }))
  }))
  validation {
    condition     = sum([for pool in var.control_plane_nodepools : length(pool.nodes)]) > 0
    error_message = "At least one control-plane node is required."
  }
}
variable "worker_nodepools" {
  type = list(object({
    name                   = string
    cpu_hot_add_enabled    = optional(bool, false)
    memory_hot_add_enabled = optional(bool, false)
    nodes = map(object({
      cpu        = number
      memory_mb  = number
      disk_gb    = number
      ip_address = string
      gateway    = string
      dns        = list(string)
    }))
  }))
  default = []
}
variable "flannel_backend_port" {
  description = "UDP port for Flannel VXLAN"
  type        = number
  default     = 8472

  validation {
    condition     = var.flannel_backend_port >= 1 && var.flannel_backend_port <= 65535
    error_message = "Flannel backend port must be between 1 and 65535."
  }
}
#=============== Cluster Upgrade ===============

variable "bash_interpreter" {
  description = "Bash interpreter used by Talos lifecycle scripts"
  type        = string
  default     = "bash"
}
#=============== Metrics Server ===============

variable "metrics_server_enabled" {
  description = "Enable Metrics Server"
  type        = bool
  default     = true
}

variable "metrics_server_helm_version" {
  description = "Metrics Server Helm chart version"
  type        = string
  default     = "3.14.0"
}

variable "metrics_server_replicas" {
  description = "Number of Metrics Server replicas"
  type        = number
  default     = 2

  validation {
    condition     = var.metrics_server_replicas >= 1
    error_message = "Metrics Server replicas must be at least 1."
  }
}
