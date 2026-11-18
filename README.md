# terraform-vsphere-kubernetes

Terraform module for deploying and managing Talos Linux Kubernetes clusters on VMware vSphere.

The module supports cluster provisioning, nodepool scaling, Talos OS rolling upgrades, and Kubernetes version upgrades.

## Features

- Provision Talos Linux virtual machines from an existing vSphere template.
- Configure multiple control-plane and worker nodes using nodepools.
- Scale control-plane and worker nodepools up or down through Terraform.
- Configure static IP addresses, gateways, DNS and NTP servers.
- Configure a Kubernetes API Virtual IP (VIP).
- Enable CPU Hot Add and Memory Hot Add per nodepool.
- Generate Talos machine configurations and credentials.
- Bootstrap the Kubernetes cluster.
- Install Flannel CNI.
- Deploy Metrics Server.
- Perform automated Talos OS rolling upgrades.
- Perform Kubernetes version upgrades through Talos.
- Reconcile newly added nodes with the configured Talos and Kubernetes versions.
- Export kubeconfig and talosconfig.

## Requirements

- VMware vSphere with an existing datacenter, datastore, network and resource pool.
- Talos Linux VM template available in vSphere.
- Terraform with the required providers.
- Network connectivity to the Talos nodes and Kubernetes API.
- `talosctl`, `kubectl` and Bash for lifecycle scripts.
- Sufficient control-plane capacity to maintain etcd quorum during scaling and maintenance.

## Repository structure

```text
.
├── addons/
│   └── metrics-server/
├── examples/
│   ├── single-control-plane/
│   └── ha-cluster/
├── templates/
├── data.tf
├── lifecycle.tf
├── metrics_server.tf
├── nodepool.tf
├── outputs.tf
├── talos.tf
├── variables.tf
├── versions.tf
└── vsphere_vm.tf
```

The repository root contains the reusable Terraform module.

The `examples/single-control-plane` directory demonstrates a basic cluster deployment. The `examples/ha-cluster` directory demonstrates a highly available cluster with multiple control-plane and worker nodes.

## Quick start

1. Navigate to an example directory:

   ```bash
   cd examples/ha-cluster
   ```

2. Review `main.tf` and adjust the nodepool settings, IP addresses, VM resources and vSphere parameters for your environment.

3. Configure sensitive variables securely, for example:

   ```bash
   export TF_VAR_vsphere_password="YOUR_PASSWORD"
   ```

4. Initialize Terraform:

   ```bash
   terraform init
   ```

5. Validate and review the deployment:

   ```bash
   terraform validate
   terraform plan
   ```

6. Deploy the cluster:

   ```bash
   terraform apply
   ```

7. Export the generated configurations (when exposed by the example root module):

   ```bash
   terraform output -raw kubeconfig > kubeconfig
   terraform output -raw talosconfig > talosconfig
   ```

## Nodepools

Control-plane and worker nodes are configured through separate nodepool definitions.

Each nodepool supports:

- `name` — nodepool name.
- `cpu_hot_add_enabled` — enable CPU Hot Add.
- `memory_hot_add_enabled` — enable Memory Hot Add.
- `nodes` — map of virtual machines and their configurations.

Each node defines CPU, memory, disk size, static IP address, gateway and DNS servers.

Virtual machine names are generated using:

```text
<nodepool-name>-<node-name>
```

For example:

```text
talos-control-plane-1
talos-control-plane-2
talos-control-plane-3
talos-worker-1
talos-worker-2
talos-worker-3
```

## Cluster scaling

The module supports scaling control-plane and worker nodepools by modifying their node definitions.

### Scale-out

1. Add new node definitions to the appropriate nodepool.
2. Run `terraform plan` to review the changes.
3. Run `terraform apply`.

Terraform provisions the additional virtual machines, applies their Talos machine configurations, and reconciles the nodes with the configured Talos and Kubernetes versions.

### Scale-in

1. Remove the corresponding node definitions from the nodepool.
2. Run `terraform plan` and verify which resources will be destroyed.
3. Run `terraform apply`.

The module uses Talos machine reset operations during node removal. Control-plane scale-in must preserve etcd quorum.

Laboratory tests have covered individual control-plane removal, individual worker removal, and removal of multiple workers. Scale-out has been tested with both individual and multiple nodes.

## Kubernetes networking

The module configures a Kubernetes API Virtual IP for control-plane access and deploys Flannel as the cluster CNI.

The VIP must be available on the configured network and reachable from Kubernetes clients.

## Talos OS upgrades

The module supports automated rolling upgrades of Talos OS using `talosctl`.

The workflow:

1. Detects the installed Talos version on each node.
2. Compares installed versions with the configured target version.
3. Waits for the expected Kubernetes nodes to become Ready.
4. Checks cluster health before upgrades.
5. Upgrades control-plane nodes sequentially, followed by workers.
6. Waits for the Talos API and Kubernetes node readiness after each upgrade.
7. Verifies versions and cluster health at the end.

Nodes already running the target version are skipped. Newly provisioned nodes from older Talos templates can be reconciled to the target version.

Automated Talos OS downgrades are not supported.

## Kubernetes upgrades

The module supports automated Kubernetes version upgrades using `talosctl upgrade-k8s`.

Kubernetes version reconciliation runs after Talos OS reconciliation, including when newly added nodes start with an older Kubernetes version.

Before upgrading:

- Review the Terraform execution plan.
- Verify control-plane and etcd health.
- Confirm Talos and Kubernetes version compatibility.
- Ensure backups and a tested recovery procedure are available.
- Avoid unrelated disruptive infrastructure changes during upgrades.

## Important limitations

- Control-plane scale-down must preserve etcd quorum.
- Scaling down to a single control-plane node reduces availability.
- VM resource changes may require shutdown and restart.
- Rolling VM hardware maintenance is not automatically orchestrated.
- Automated Talos OS and Kubernetes downgrades are not supported.
- Production use requires appropriate backup, monitoring and recovery procedures.

## Security

Talos machine configurations, Kubernetes credentials and Terraform state may contain sensitive information.

- Store Terraform state in a secured backend.
- Do not commit `terraform.tfstate`, `terraform.tfvars`, kubeconfig or talosconfig.
- Restrict access to vSphere VM configuration properties.
- Use environment variables or a secrets-management solution for credentials.
- Restrict access to Terraform execution environments and generated configuration files.

## Testing and validation

The module has been tested in a laboratory VMware vSphere environment.

|                 Scenario                | Status |
|-----------------------------------------|--------|
| Initial Kubernetes cluster provisioning | Tested |
| Multiple control-plane and worker nodes | Tested |
| Single-node scale-out                   | Tested |
| Multiple-node scale-out                 | Tested |
| Single control-plane scale-in           | Tested |
| Single worker scale-in                  | Tested |
| Multiple worker scale-in                | Tested |
| Talos OS rolling upgrade                | Tested |
| Kubernetes version upgrade              | Tested |
| Version reconciliation after scale-out  | Tested |

## Status

**Active development — core lifecycle workflows validated.**

Provisioning, high-availability cluster deployment, nodepool scaling, Talos OS rolling upgrades, Kubernetes version upgrades and version reconciliation have been tested in a laboratory vSphere environment.

The module supports the core cluster lifecycle: provisioning, scaling, upgrading and destruction.

Production deployments should include suitable monitoring, backups, disaster recovery procedures and additional failure-recovery testing.
