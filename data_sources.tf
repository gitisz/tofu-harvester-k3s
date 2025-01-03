data "harvester_network" "default_vm_network" {
  name      = "default-vm-network"
  namespace = "default"
}

data "harvester_image" "debian_12_genericcloud_amd6" {
  display_name      = "debian-12-genericcloud-amd64-20241201-1948.qcow2"
  namespace         = "default"
}

data "kubernetes_nodes" "harvester_nodes" {}

# Get the total node count
variable "node_count" {
  default = 0
}

output "total_node_count" {
  value = length(data.kubernetes_nodes.harvester_nodes.nodes)
}

data "external" "next_ip" {
  count = length(data.kubernetes_nodes.harvester_nodes.nodes) - 1
  program = ["python3", "./scripts/next_ip.py"]
  query = {
    start_ip  = var.cluster_start_ip
    increment = count.index + 1
  }
}

data "kubernetes_nodes" "harvester_hosts" {}

locals {
  cert_manager_issuer_environment = var.use_production_issuer ? "production" : "staging"
}
