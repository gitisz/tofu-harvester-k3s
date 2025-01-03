resource "harvester_virtualmachine" "server_first_node" {
  name      = "${var.server_host_name_prefix}-0"
  namespace = "default"
  cpu    = 4
  memory = "4Gi"
  efi         = false
  secure_boot = false

  network_interface {
    name         = "nic-1"
    network_name = data.harvester_network.default_vm_network.id
  }

  disk {
    name       = "server-disk-0"
    type       = "disk"
    size       = "10Gi"
    bus        = "virtio"
    boot_order = 1
    image       = data.harvester_image.debian_12_genericcloud_amd6.id
    auto_delete = true
  }

  input {
    name = "tablet"
    type = "tablet"
    bus  = "usb"
  }

  cloudinit {
    user_data_secret_name    = harvester_cloudinit_secret.cloud_config_server_first_node.name
    network_data_secret_name = harvester_cloudinit_secret.cloud_config_server_first_node.name
  }

  connection {
    type        = "ssh"
    user        = "administrator"
    host        = "${var.cluster_start_ip}"
    private_key = file(".ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for VM to be up...'",
      "while ! sudo test -f /var/lib/rancher/k3s/server/node-token; do echo 'Waiting for K3S token'; sleep 10; done",
      "while ! sudo test -f /k3s/local-k3s.yaml; do echo 'Waiting for K3S Kube Config'; sleep 10; done",
      "echo 'VM, K3S Token, and Kube Config are ready 🚀'"
    ]
  }

  provisioner "local-exec" {
    command = "pip3 install -r ./scripts/requirements.txt && python3 ./scripts/fetch_k3s_config.py ${var.SSH_ADMIN_USER} ${var.cluster_start_ip} ${var.server_alb_ip} ${var.server_host_name_prefix}"
  }
}

resource "harvester_virtualmachine" "server_other_node" {
  count       = length(data.kubernetes_nodes.harvester_nodes.nodes) > var.server_node_count ? var.server_node_count - 1 : length(data.kubernetes_nodes.harvester_nodes.nodes) - 1
  name        = "${var.server_host_name_prefix}-${count.index + 1}"
  namespace   = "default"
  cpu         = 4
  memory      = "4Gi"
  efi         = false
  secure_boot = false
  depends_on  = [ harvester_virtualmachine.server_first_node ]

  network_interface {
    name         = "nic-1"
    network_name = data.harvester_network.default_vm_network.id
  }

  disk {
    name       = "server-disk-${count.index + 1}"
    type       = "disk"
    size       = "10Gi"
    bus        = "virtio"
    boot_order = 1
    image       = data.harvester_image.debian_12_genericcloud_amd6.id
    auto_delete = true
  }

  input {
    name = "tablet"
    type = "tablet"
    bus  = "usb"
  }

  cloudinit {
    user_data_secret_name    = harvester_cloudinit_secret.cloud_config_server_other_node[count.index].name
    network_data_secret_name = harvester_cloudinit_secret.cloud_config_server_other_node[count.index].name
  }
}



#                        )              )    ) (         (
#    (     (          ( /(   *   )   ( /( ( /( )\ )      )\ )
#    )\    )\ )   (   )\())` )  /(   )\()))\()|()/(  (  (()/(
# ((((_)( (()/(   )\ ((_)\  ( )(_)) ((_)\((_)\ /(_)) )\  /(_))
#  )\ _ )\ /(_))_((_) _((_)(_(_())   _((_) ((_|_))_ ((_)(_))
#  (_)_\(_|_)) __| __| \| ||_   _|  | \| |/ _ \|   \| __/ __|
#   / _ \   | (_ | _|| .` |  | |    | .` | (_) | |) | _|\__ \
#  /_/ \_\   \___|___|_|\_|  |_|    |_|\_|\___/|___/|___|___/

resource "harvester_virtualmachine" "agent_first_node" {
  name        = "${var.agent_host_name_prefix}-0"
  namespace   = "default"
  cpu         = 4
  memory      = "4Gi"
  efi         = false
  secure_boot = false
  depends_on = [ harvester_virtualmachine.server_other_node ]

  network_interface {
    name         = "nic-1"
    network_name = data.harvester_network.default_vm_network.id
  }

  disk {
    name       = "agent-disk-0"
    type       = "disk"
    size       = "10Gi"
    bus        = "virtio"
    boot_order = 1
    image       = data.harvester_image.debian_12_genericcloud_amd6.id
    auto_delete = true
  }

  input {
    name = "tablet"
    type = "tablet"
    bus  = "usb"
  }

  cloudinit {
    user_data_secret_name    = harvester_cloudinit_secret.cloud_config_agent_first_node.name
    network_data_secret_name = harvester_cloudinit_secret.cloud_config_agent_first_node.name
  }
}

resource "harvester_virtualmachine" "agent_other_node" {
  count       = length(data.kubernetes_nodes.harvester_nodes.nodes) > var.agent_node_count ? var.agent_node_count - 1 : length(data.kubernetes_nodes.harvester_nodes.nodes) - 1
  name        = "${var.agent_host_name_prefix}-${count.index + 1}"
  namespace   = "default"
  cpu         = 4
  memory      = "4Gi"
  efi         = false
  secure_boot = false
  depends_on = [ harvester_virtualmachine.server_other_node ]

  network_interface {
    name         = "nic-1"
    network_name = data.harvester_network.default_vm_network.id
  }

  disk {
    name       = "agent-disk-0"
    type       = "disk"
    size       = "10Gi"
    bus        = "virtio"
    boot_order = 1
    image       = data.harvester_image.debian_12_genericcloud_amd6.id
    auto_delete = true
  }

  input {
    name = "tablet"
    type = "tablet"
    bus  = "usb"
  }

  cloudinit {
    user_data_secret_name    = harvester_cloudinit_secret.cloud_config_agent_other_node[count.index].name
    network_data_secret_name = harvester_cloudinit_secret.cloud_config_agent_other_node[count.index].name
  }
}

