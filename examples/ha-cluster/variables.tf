variable "vsphere_user" {
  type    = string
  default = ""
}
variable "vsphere_password" {
  type      = string
  default   = ""
  sensitive = true
}
variable "vsphere_server" {
  type    = string
  default = ""
}
variable "bash_interpreter" {
  description = "Set this value if using Windows Git Bash"
  type        = string
  default     = ""
}
variable "vsphere_datacenter" {
  type    = string
  default = ""
}
variable "vsphere_datastore" {
  type    = string
  default = ""
}
variable "vsphere_network" {
  type    = string
  default = ""
}
variable "vsphere_resource_pool" {
  type    = string
  default = ""
}
variable "vsphere_folder" {
  type    = string
  default = ""
}
variable "talos_template_name" {
  type    = string
  default = ""
}
variable "cluster_name" {
  type    = string
  default = ""
}
variable "control_plane_vip" {
  type    = string
  default = ""
}
variable "talos_version" {
  type    = string
  default = ""
}
variable "kubernetes_version" {
  type    = string
  default = ""
}
variable "ntp_servers" {
  type = list(string)
  default = [
    ""
  ]
}
variable "bootstrap_node_name" {
  type    = string
  default = ""
}
