variable "server_host_name_prefix" {
  default = "tofu-hrvstr-server"
}

variable "agent_host_name_prefix" {
  default = "tofu-hrvstr-agent"
}

variable "server_node_count" {
  default = 3
}

variable "agent_node_count" {
  default = 3
}

variable "cluster_start_ip" {
  default = "10.10.10.191"
}

variable "server_alb_ip" {
  default = "10.10.10.190"
}

variable "agent_alb_primary_ip" {
  default = "10.10.10.194"
}

variable "agent_alb_additional_ips" {
  description = "List of IP addresses for agent ALB"
  type        = list(string)
  default     = [
    "10.10.10.195",
    "10.10.10.196",
    "10.10.10.197",
    "10.10.10.198",
    "10.10.10.199",
  ]
}

variable "with_cert_manager" {
  default = "false"
}

variable "use_production_issuer" {
  description = "Use production issuer if true, otherwise use the staging issuer."
  type        = bool
  default     = false
}

variable "with_traefik" {
  default = "false"
}

variable "SSH_ADMIN_USER" {
  sensitive   = true
}

variable "CERT_MANAGER_CLOUDFLARE_EMAIL" {
  sensitive   = true
}

variable "CERT_MANAGER_CLOUDFLARE_API_TOKEN" {
  sensitive   = true
}

variable "CERT_MANAGER_CLOUDFLARE_DNS_SECRET_NAME_PREFIX" {
  sensitive   = true
}

variable "CERT_MANAGER_CLOUDFLARE_DNS_ZONE" {
  sensitive   = true
}

variable "CERT_MANAGER_LETSENCRYPT_EMAIL" {
  sensitive   = true
}

variable "TRAEFIK_DASHBOARD_AUTH" {
  sensitive   = true
}

variable "TRAEFIK_DASHBOARD_FQDN" {
  sensitive   = true
}
