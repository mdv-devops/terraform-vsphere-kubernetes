# HA Cluster Example

This example deploys a highly available Talos Linux Kubernetes cluster on VMware vSphere using the `terraform-vsphere-kubernetes` module.

The example defines **3 control-plane nodes and 3 worker nodes**, with a Kubernetes API virtual IP (VIP).

## Prerequisites

- Terraform >= 1.6
- VMware vSphere with an existing Talos VM template
- Available datastore, network, resource pool and VM folder
- `talosctl`, `kubectl` and Bash
- Network connectivity to the cluster nodes and Kubernetes API VIP
- Sufficient control-plane capacity to preserve etcd quorum during maintenance

## Cluster configuration

Node definitions are configured in `main.tf`.

|         Node          |   IP address  | CPU |   RAM   | Disk  |
|-----------------------|---------------|----:|--------:|------:|
| talos-control-plane-1 | 192.168.43.10 |  2  | 4096 MB | 40 GB |
| talos-control-plane-2 | 192.168.43.11 |  2  | 4096 MB | 40 GB |
| talos-control-plane-3 | 192.168.43.12 |  2  | 4096 MB | 40 GB |
| talos-worker-1        | 192.168.43.13 |  4  | 4096 MB | 40 GB |
| talos-worker-2        | 192.168.43.14 |  4  | 4096 MB | 40 GB |
| talos-worker-3        | 192.168.43.15 |  4  | 4096 MB | 40 GB |

CPU Hot Add and Memory Hot Add are enabled for both nodepools.

Update the IP addresses and VM resources in `main.tf` before deploying to a different environment.

## Deployment

### 1. Configure variables

Create `terraform.tfvars` in this directory and specify your vSphere and Talos settings:

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

Set the vSphere password through an environment variable rather than committing it to the repository:

```bash
export TF_VAR_vsphere_password="YOUR_PASSWORD"
```

The example provider uses `allow_unverified_ssl = true`, which is suitable only for a trusted laboratory environment. Use verified TLS certificates for production deployments.

### 2. Initialize and validate

```bash
terraform init
terraform validate
```

### 3. Review and apply

```bash
terraform plan
terraform apply
```

Review the proposed VM, nodepool and lifecycle changes before approving the operation.

## Accessing the cluster

Export the generated configurations:

```bash
terraform output -raw kubeconfig > kubeconfig
terraform output -raw talosconfig > talosconfig
```

Configure the CLI tools:

```bash
export KUBECONFIG="$PWD/kubeconfig"
export TALOSCONFIG="$PWD/talosconfig"
```

Verify Kubernetes:

```bash
kubectl get nodes -o wide
kubectl get pods -A
```

Verify Talos cluster health using control-plane Talos API endpoints:

```bash
talosctl --talosconfig talosconfig --nodes 192.168.43.10 version
talosctl --talosconfig talosconfig --endpoints 192.168.43.10,192.168.43.11,192.168.43.12 --nodes 192.168.43.10 health
talosctl --talosconfig talosconfig --endpoints 192.168.43.10 --nodes 192.168.43.10 etcd members
```

The Kubernetes API VIP (`192.168.43.20`) is intended for Kubernetes API access. Use real control-plane addresses as Talos API endpoints.

## Cluster scaling

Scale control-plane or worker nodepools by adding or removing node definitions in `main.tf`, then run:

```bash
terraform plan
terraform apply
```

### Scale-out

New VMs are provisioned from the Talos template and receive their machine configurations. The lifecycle workflow waits for the new nodes to join the cluster and reconciles their Talos OS and Kubernetes versions with the configured targets.

### Scale-in

Removing node definitions triggers the configured Talos node reset and VM removal workflow. The module's scale-in behavior has been tested for individual control-plane nodes and for individual and multiple workers.

**Important:** Before reducing the control-plane count, ensure that the remaining nodes can maintain etcd quorum. Review the Terraform plan carefully, especially when removing multiple nodes or combining scaling with other changes.

## Talos OS upgrades

Change `talos_version` in `terraform.tfvars`, then review and apply the plan:

```bash
terraform plan
terraform apply
```

The module performs Talos OS rolling reconciliation: it detects node versions, checks cluster health, upgrades control-plane nodes sequentially, then upgrades workers. Nodes already at the target version are skipped. It waits for Talos API availability and Kubernetes node readiness as part of the workflow.

Talos OS downgrades are not supported by the automated workflow.

## Kubernetes upgrades

Change `kubernetes_version` in `terraform.tfvars`, then run:

```bash
terraform plan
terraform apply
```

The module uses `talosctl upgrade-k8s` to reconcile the cluster with the requested Kubernetes version, including after scale-out when newly created nodes may start with an older version.

Talos OS reconciliation runs before Kubernetes reconciliation when both are required. Confirm version compatibility and cluster health before upgrading.

## Tested scenarios

The following operations have been tested in the laboratory vSphere environment:

|             Scenario             | Status |
|----------------------------------|--------|
| Initial HA cluster deployment    | Tested |
| Add one node                     | Tested |
| Add multiple nodes               | Tested |
| Remove one control-plane node    | Tested |
| Remove one worker node           | Tested |
| Remove multiple worker nodes     | Tested |
| Talos OS upgrade                 | Tested |
| Kubernetes upgrade               | Tested |

These results validate the core lifecycle workflows in the test environment; they do not replace failure-recovery and production-readiness testing.

## Useful commands

Run these commands from the `examples/ha-cluster` directory. After exporting `KUBECONFIG` and `TALOSCONFIG` as shown above, the CLI tools can use those files automatically. Replace IP addresses if your nodepool configuration differs.

### Terraform

Initialize or upgrade providers:

```bash
terraform init -upgrade
```

Validate and inspect configuration:

```bash
terraform fmt -check -recursive
terraform validate
terraform plan
terraform state list
terraform output
```

### Kubernetes

Inspect nodes, versions, resource usage and workloads:

```bash
kubectl get nodes -o wide
kubectl top nodes
kubectl get pods -A -o wide
kubectl get pods -n kube-system -o wide
kubectl describe node talos-control-plane-1
kubectl version
kubectl get --raw='/readyz?verbose'
```

`kubectl top` requires Metrics Server to be available.

### Talos Linux

Inspect Talos versions, health, membership, services, logs and networking:

```bash
talosctl --nodes 192.168.43.10 version
talosctl --endpoints 192.168.43.10,192.168.43.11,192.168.43.12 --nodes 192.168.43.10 health
talosctl --nodes 192.168.43.10 get members
talosctl --nodes 192.168.43.10 get machineconfig
talosctl --nodes 192.168.43.10 services
talosctl --nodes 192.168.43.10 logs kubelet --tail 100
talosctl --nodes 192.168.43.10 dmesg
talosctl --nodes 192.168.43.10 get addresses
talosctl --nodes 192.168.43.10 get routes
```

### etcd

Check etcd membership, status, alarms and logs:

```bash
talosctl --nodes 192.168.43.10 etcd members
talosctl --nodes 192.168.43.10 etcd status
talosctl --nodes 192.168.43.10 etcd alarm list
talosctl --nodes 192.168.43.10 logs etcd --tail 100
```

Verify etcd health and quorum before removing or upgrading control-plane nodes.

### Scaling verification

After changing the nodepool definitions and applying Terraform:

```bash
terraform plan
terraform apply
kubectl get nodes -o wide
talosctl --nodes 192.168.43.10 get members
talosctl --nodes 192.168.43.10 etcd members
```

### Upgrade verification

Check Talos versions across all six nodes (Git Bash):

```bash
for ip in 192.168.43.{10..15}; do echo "=== $ip ==="; talosctl --nodes "$ip" version; done
```

Check Kubernetes versions and node readiness:

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,VERSION:.status.nodeInfo.kubeletVersion,READY:.status.conditions[?(@.type=="Ready")].status
kubectl get pods -n kube-system -o wide
talosctl --nodes 192.168.43.10 health
```

### Troubleshooting

Inspect nodes, non-running pods and recent events:

```bash
kubectl get nodes -o wide
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
kubectl get events -A --sort-by=.metadata.creationTimestamp
```

Inspect a problematic Talos node:

```bash
talosctl --nodes 192.168.43.12 logs kubelet --tail 200
talosctl --endpoints 192.168.43.10 --nodes 192.168.43.12 version
talosctl --nodes 192.168.43.12 services
```

### Destroy the cluster

Review the destruction plan before removing infrastructure:

```bash
terraform plan -destroy
terraform destroy
```

**Warning:** Destroying the cluster is destructive. Back up important data and review all planned resource removals first.

## Important notes

- The example uses static IPv4 addresses.
- The Kubernetes API VIP must be unused and reachable on the selected network.
- Do not commit `terraform.tfvars`, `terraform.tfstate`, kubeconfig or talosconfig.
- Store Terraform state securely; generated credentials and VM configuration may contain secrets.
- VM CPU and memory changes may require a restart.
- Maintain etcd quorum when scaling control-plane nodes down.
- Use backups and a tested recovery procedure before disruptive upgrades.
- This example is intended for laboratory and development environments; production use requires additional operational safeguards.
