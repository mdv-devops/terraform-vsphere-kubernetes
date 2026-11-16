# terraform-vsphere-kubernetes

Terraform module for deploying and managing Talos Linux Kubernetes clusters on VMware vSphere.

## Features

- Provision Talos Linux virtual machines from an existing vSphere template.
- Configure multiple control-plane and worker nodes using nodepools.
- Configure static IP addresses, gateways, DNS and NTP servers.
- Configure a Kubernetes API Virtual IP (VIP).
- Enable CPU Hot Add and Memory Hot Add per nodepool.
- Generate Talos machine configurations and credentials.
- Bootstrap the Kubernetes cluster.
- Install Flannel CNI.
- Deploy Metrics Server.
- Support Kubernetes version upgrades through Talos.
- Export kubeconfig and talosconfig.

## Requirements

- VMware vSphere with an existing datacenter, datastore, network and resource pool.
- Talos Linux VM template available in vSphere.
- Terraform with the required providers.
- Network connectivity to the Talos nodes and Kubernetes API.
- `talosctl`, `kubectl` and Bash for lifecycle scripts.

## Repository structure

```text
.
├── addons/
│   └── metrics-server/
├── examples/
│   └── single-control-plane/
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

The `examples/single-control-plane` directory contains a root Terraform configuration demonstrating how to deploy the module.

## Quick start

1. Navigate to the example directory:

   ```bash
   cd examples/single-control-plane
   ```

2. Review the configuration in `main.tf` and adjust the nodepool settings, IP addresses, VM resources and vSphere parameters for your environment.

3. Configure sensitive variables securely. For example:

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

7. Export the generated configurations:

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

## Kubernetes networking

The module configures a Kubernetes API Virtual IP for control-plane access and deploys Flannel as the cluster CNI.

The VIP must be available on the configured network and reachable from Kubernetes clients.

## Kubernetes upgrades

The module includes lifecycle scripts for Kubernetes version upgrades using `talosctl upgrade-k8s`.

Before upgrading:

- Review the Terraform execution plan.
- Verify the health of all control-plane nodes and etcd.
- Ensure that a tested recovery procedure is available.
- Avoid simultaneous disruptive infrastructure changes.

Talos OS upgrades are not currently implemented as a complete automated rolling-upgrade workflow.

## Important limitations

- Safe automatic removal of Kubernetes nodes is not fully implemented.
- Control-plane scale-down requires special care to preserve etcd quorum.
- VM resource changes may require a shutdown and restart.
- Rolling VM maintenance is not automatically orchestrated.
- Kubernetes upgrade operations should be tested before production use.

## Security

Talos machine configurations, Kubernetes credentials and Terraform state may contain sensitive information.

- Store Terraform state in a secured backend.
- Do not commit `terraform.tfstate`, `terraform.tfvars`, kubeconfig or talosconfig.
- Restrict access to vSphere VM configuration properties.
- Use environment variables or an appropriate secrets-management solution for credentials.

## Status

The module is under active development and has been tested in a laboratory vSphere environment.

Production deployment requires additional lifecycle and recovery testing.