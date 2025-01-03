
terraform {
  required_providers {
    harvester = {
      source = "harvester/harvester"
      version = "0.6.6"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "harvester" {
  kubeconfig = "~/.kube/config"
  kubecontext = "local"
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "local"
}