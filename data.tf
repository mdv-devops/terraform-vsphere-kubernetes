
data "vsphere_datacenter" "this" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "this" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_network" "this" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_resource_pool" "this" {
  name          = var.vsphere_resource_pool
  datacenter_id = data.vsphere_datacenter.this.id
}

data "vsphere_virtual_machine" "this" {
  name          = var.talos_template_name
  datacenter_id = data.vsphere_datacenter.this.id
}

data "talos_machine_configuration" "this" {
  for_each = local.nodes

  cluster_name       = var.cluster_name
  cluster_endpoint   = var.cluster_endpoint
  machine_type       = each.value.role
  talos_version      = talos_machine_secrets.this.talos_version
  kubernetes_version = terraform_data.kubernetes_bootstrap_version.output
  machine_secrets    = talos_machine_secrets.this.machine_secrets

  config_patches = concat(
    [
      yamlencode({
        machine = {
          network = {
            interfaces = [
              merge(
                {
                  interface = var.talos_network_interface
                  addresses = [each.value.ip_address]
                  routes = [{
                    network = "0.0.0.0/0"
                    gateway = each.value.gateway
                  }]
                },
                each.value.role == "controlplane" && var.control_plane_vip != null ? {
                  vip = {
                    ip = var.control_plane_vip
                  }
                } : {}
              )
            ]
          }

          time = {
            servers = var.ntp_servers
          }
        }
      }),

      yamlencode({
        apiVersion = "v1alpha1"
        kind       = "ResolverConfig"

        nameservers = [
          for dns in each.value.dns : {
            address = dns
          }
        ]
      }),

      yamlencode({
        apiVersion = "v1alpha1"
        kind       = "HostnameConfig"

        hostname = each.key
        auto     = "off"
      })
    ],

    each.value.role == "controlplane" ? concat(
      [
        yamlencode({
          apiVersion = "v1alpha1"
          kind       = "KubeTalosAPIAccessConfig"

          allowedRoles = [
            "os:reader"
          ]

          allowedKubernetesNamespaces = [
            "kube-system"
          ]
        }),
        yamlencode({
          apiVersion  = "v1alpha1"
          kind        = "KubeFlannelCNIConfig"
          backendType = "vxlan"
          backendPort = var.flannel_backend_port
        })
      ],

      module.metrics_server.config_patches
    ) : []
  )
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration

  endpoints = [
    for name, node in local.control_plane_nodes :
    split("/", node.ip_address)[0]
  ]

  nodes = [
    for name, node in local.nodes :
    split("/", node.ip_address)[0]
  ]
}
