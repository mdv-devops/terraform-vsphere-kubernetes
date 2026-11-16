# HA cluster Example

This example deploys a Talos Linux Kubernetes cluster on VMware vSphere using the `terraform-vsphere-kubernetes` module.

Despite the directory name, the current configuration deploys **3 control-plane nodes and 3 worker nodes**.

## Prerequisites

- Terraform >= 1.6
- VMware vSphere with an existing Talos VM template
- Available datastore, network, resource pool and VM folder
- `talosctl`, `kubectl` and Bash
- Network connectivity to the cluster nodes and Kubernetes API VIP

## Cluster configuration

The node configuration is defined in `main.tf`.

| Node                  |  IP address   | CPU | RAM     | Disk  |
|-----------------------|---------------|-----|---------|-------|
| talos-control-plane-1 | 192.168.43.10 |  2  | 4096 MB | 40 GB |
| talos-control-plane-2 | 192.168.43.11 |  2  | 4096 MB | 40 GB |
| talos-control-plane-3 | 192.168.43.12 |  2  | 4096 MB | 40 GB |
| talos-worker-1        | 192.168.43.13 |  4  | 4096 MB | 40 GB |
| talos-worker-2        | 192.168.43.14 |  4  | 4096 MB | 40 GB |
| talos-worker-3        | 192.168.43.15 |  4  | 4096 MB | 40 GB |

CPU Hot Add and Memory Hot Add are enabled for both nodepools.

Update the IP addresses and VM resources in `main.tf` before deploying into a different environment.

## Deployment

### 1. Configure variables

Create `terraform.tfvars` in this directory and specify your vSphere and Talos settings.

For example:

```hcl
vsphere_user          = "administrator@vsphere.local"
vsphere_server        = "vcenter.example.local"
vsphere_datacenter    = "datacenter"
vsphere_datastore     = "datastore"
vsphere_network       = "network"
vsphere_resource_pool = "resource-pool"
vsphere_folder        = "DevOps"
talos_template_name   = "talos-template"

cluster_name        = "talos-kubernetes"
control_plane_vip   = "192.168.43.20"
talos_version       = "v1.14.6"
kubernetes_version  = "v1.37.0"
bootstrap_node_name = "talos-control-plane-1"

ntp_servers = ["192.168.43.2"]
```

Set the vSphere password using an environment variable rather than storing it in the repository:

```bash
export TF_VAR_vsphere_password="YOUR_PASSWORD"
```

The example provider currently uses `allow_unverified_ssl = true`. This is intended for a laboratory environment.

### 2. Initialize Terraform

From the example directory:

```bash
terraform init
terraform validate
```

### 3. Review the plan

```bash
terraform plan
```

Check the planned virtual machines, node configuration and cluster settings.

### 4. Deploy the cluster

```bash
terraform apply
```

Review the plan before approving the operation.

## Accessing the cluster

Export the generated configurations:

```bash
terraform output -raw kubeconfig > kubeconfig
terraform output -raw talosconfig > talosconfig
```

Configure your CLI tools:

```bash
export KUBECONFIG="$PWD/kubeconfig"
export TALOSCONFIG="$PWD/talosconfig"
```

Verify Kubernetes:

```bash
kubectl get nodes -o wide
kubectl get pods -A
```

Verify Talos:

```bash
talosctl --nodes 192.168.43.10 health
```

## Kubernetes upgrades

To change the Kubernetes version, update `kubernetes_version` in `terraform.tfvars`.

Review the plan before applying:

```bash
terraform plan
terraform apply
```

The module includes Kubernetes upgrade automation using `talosctl upgrade-k8s`.

Always verify cluster health and etcd quorum before upgrading.

## Important notes

- The example uses static IPv4 addresses.
- The Kubernetes API VIP must be available on the selected network.
- Do not commit `terraform.tfvars`, `terraform.tfstate`, kubeconfig or talosconfig.
- VM CPU and memory changes may require a restart.
- Automatic safe removal of Kubernetes nodes is not fully implemented.
- This example is intended for laboratory and development environments.