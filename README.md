# tofu-harvester-k3s
This repository contains Terraform to fully automate deploying a K3S Kubernetes cluster onto Harvester, with some additional benefits like kube-vip for server load-balancing and metallb for application load balancing.

## Prerequisites
 - `~/.kube/config` file with credentials for your Harvester cluster, with context of `local`.

## Usage
This automation will create or update your `~/.kube/config` file with the credentials for your new K3S cluster, assigning the context for the cluster to the `${server_host_name_prefix}` variable. This enables you to use `kubectl` to interact with your deployed cluster, while retaining the ability to interact with any other clusters you may have.