#  (       (              (         )    ) (         (
#  )\ )    )\ )           )\ )   ( /( ( /( )\ )      )\ )
# (()/((  (()/((   (  (  (()/(   )\()))\()|()/(  (  (()/(
#  /(_))\  /(_))\  )\ )\  /(_)) ((_)\((_)\ /(_)) )\  /(_))
# (_))((_)(_))((_)((_|(_)(_))    _((_) ((_|_))_ ((_)(_))
# / __| __| _ \ \ / /| __| _ \  | \| |/ _ \|   \| __/ __|
# \__ \ _||   /\ V / | _||   /  | .` | (_) | |) | _|\__ \
# |___/___|_|_\ \_/  |___|_|_\  |_|\_|\___/|___/|___|___/

resource "harvester_cloudinit_secret" "cloud_config_server_first_node" {
  name      = "${var.server_host_name_prefix}-cloud-config-server-node-0"
  namespace = "default"
  user_data = templatefile(
    "./cloud-init/cloud-init-server-first-node.tftpl",
    {
      count                   = 0,
      host_name_prefix        = "${var.server_host_name_prefix}",
      ssh_public_key          = file(".ssh/id_rsa_pub"),
      k3s_token               = file(".k3s/k3s_token"),
      server_alb_ip           = "${var.server_alb_ip}",
      cluster_start_ip        = "${var.cluster_start_ip}",
      metallb_yaml            = indent(6, templatefile("./metallb/metallb-address-pool.yaml", {
        agent_alb_primary_ip = var.agent_alb_primary_ip
        agent_alb_additional_ips    = var.agent_alb_additional_ips
      })),
      # cert-manager
      with_cert_manager                                 = var.with_cert_manager,
      cert_manager_issuer_environment                   = local.cert_manager_issuer_environment,
      cert_manager_chart_values                         = indent(6, templatefile("./deployments/cert-manager/chart-values.yaml", {
      })),
      cert_manager_issuers_secret_cf_token              = indent(6, templatefile("./deployments/cert-manager/issuers/secret-cf-token.yaml", {
        cert_manager_cloudflare_api_token               = var.CERT_MANAGER_CLOUDFLARE_API_TOKEN
      })),
      cert_manager_issuers_letsencrypt_issuer           = indent(6, templatefile("./deployments/cert-manager/issuers/letsencrypt-${local.cert_manager_issuer_environment}.yaml", {
        cert_manager_letsencrypt_email                  = var.CERT_MANAGER_LETSENCRYPT_EMAIL,
        cert_manager_cloudflare_email                   = var.CERT_MANAGER_CLOUDFLARE_EMAIL,
        cert_manager_cloudflare_dns_zone                = var.CERT_MANAGER_CLOUDFLARE_DNS_ZONE
      })),
      cert_manager_certificates_environment_certificate = indent(6, templatefile("./deployments/cert-manager/certificates/${local.cert_manager_issuer_environment}/certificate.yaml", {
        cert_manager_cloudflare_dns_secret_name_prefix  = var.CERT_MANAGER_CLOUDFLARE_DNS_SECRET_NAME_PREFIX,
        cert_manager_cloudflare_dns_zone                = var.CERT_MANAGER_CLOUDFLARE_DNS_ZONE
      }))

      # traefik
      with_traefik                                      = var.with_traefik,
      traefik_chart_values                              = indent(6, templatefile("./deployments/traefik/chart-values.yaml", {
        agent_alb_primary_ip                            = "${var.agent_alb_primary_ip}",
        agent_alb_additional_ips                        = var.agent_alb_additional_ips
      })),
      traefik_traefik_dashboard_auth                    = indent(6, templatefile("./deployments/traefik/traefik-dashboard-auth.yaml", {
        traefik_dashboard_auth                          = "${var.TRAEFIK_DASHBOARD_AUTH}"
      })),
      traefik_traefik_dashboard_ingress                 = indent(6, templatefile("./deployments/traefik/traefik-dashboard-ingress.yaml", {
        traefik_dashboard_fqdn                          = "${var.TRAEFIK_DASHBOARD_FQDN}",
        cert_manager_cloudflare_dns_secret_name_prefix  = "${var.CERT_MANAGER_CLOUDFLARE_DNS_SECRET_NAME_PREFIX}",
        cert_manager_issuer_environment                 = local.cert_manager_issuer_environment
      })),
      traefik_traefik_dashboard_middleware              = indent(6, templatefile("./deployments/traefik/traefik-dashboard-middleware.yaml", {
      })),
      traefik_traefik_default_headers                   = indent(6, templatefile("./deployments/traefik/traefik-default-headers.yaml", {
      })),
      traefik_certificates_environment_certificate      = indent(6, templatefile("./deployments/traefik/certificates/${local.cert_manager_issuer_environment}/traefik-certificate.yaml", {
        traefik_cloudflare_dns_secret_name_prefix       = var.CERT_MANAGER_CLOUDFLARE_DNS_SECRET_NAME_PREFIX,
        traefik_cloudflare_dns_zone                     = var.CERT_MANAGER_CLOUDFLARE_DNS_ZONE
      })),
    }
  )
  network_data = templatefile(
    "./cloud-init/cloud-init-networks-static.tftpl",
    {
      ip_address            = "${var.cluster_start_ip}"
    }
  )
}

resource "harvester_cloudinit_secret" "cloud_config_server_other_node" {
  count     = var.server_node_count - 1
  name      = "${var.server_host_name_prefix}-cloud-config-server-node-${count.index + 1}"
  user_data = templatefile(
    "./cloud-init/cloud-init-server-other-node.tftpl",
    {
      count                 = count.index + 1,
      host_name_prefix      = "${var.server_host_name_prefix}",
      ssh_public_key        = file(".ssh/id_rsa_pub"),
      k3s_token             = file(".k3s/k3s_token"),
      server_alb_ip         = "${var.server_alb_ip}",
      cluster_start_ip      = "${var.cluster_start_ip}"
    }
  )
  network_data = templatefile(
    "./cloud-init/cloud-init-networks-static.tftpl",
    {
      ip_address            = data.external.next_ip[count.index].result.next_ip
    }
  )
}


#                        )              )    ) (         (
#    (     (          ( /(   *   )   ( /( ( /( )\ )      )\ )
#    )\    )\ )   (   )\())` )  /(   )\()))\()|()/(  (  (()/(
# ((((_)( (()/(   )\ ((_)\  ( )(_)) ((_)\((_)\ /(_)) )\  /(_))
#  )\ _ )\ /(_))_((_) _((_)(_(_())   _((_) ((_|_))_ ((_)(_))
#  (_)_\(_|_)) __| __| \| ||_   _|  | \| |/ _ \|   \| __/ __|
#   / _ \   | (_ | _|| .` |  | |    | .` | (_) | |) | _|\__ \
#  /_/ \_\   \___|___|_|\_|  |_|    |_|\_|\___/|___/|___|___/

resource "harvester_cloudinit_secret" "cloud_config_agent_first_node" {
  name      = "${var.agent_host_name_prefix}-cloud-config-agent-node-0"
  user_data = templatefile(
    "./cloud-init/cloud-init-agent-first-node.tftpl",
    {
      count                   = 0,
      host_name_prefix        = "${var.agent_host_name_prefix}",
      ssh_public_key          = file(".ssh/id_rsa_pub"),
      k3s_token               = file(".k3s/k3s_token"),
      server_alb_ip           = "${var.server_alb_ip}",
      cluster_start_ip        = "${var.cluster_start_ip}",
    }
  )
  network_data = templatefile(
    "./cloud-init/cloud-init-networks-dhcp.tftpl",
    {
    }
  )
}

resource "harvester_cloudinit_secret" "cloud_config_agent_other_node" {
  count                     = var.agent_node_count - 1
  name                      = "${var.agent_host_name_prefix}-cloud-config-agent-node-${count.index + 1}"
  user_data = templatefile(
    "./cloud-init/cloud-init-agent-other-node.tftpl",
    {
      count                   = count.index + 1,
      host_name_prefix        = "${var.agent_host_name_prefix}",
      ssh_public_key          = file(".ssh/id_rsa_pub"),
      k3s_token               = file(".k3s/k3s_token"),
      server_alb_ip           = "${var.server_alb_ip}",
      cluster_start_ip        = "${var.cluster_start_ip}",
    }
  )
  network_data = templatefile(
    "./cloud-init/cloud-init-networks-dhcp.tftpl",
    {
    }
  )
}

