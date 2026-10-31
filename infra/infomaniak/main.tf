terraform {
  required_version = ">= 1.5"

  required_providers {
    infomaniak = {
      source  = "Infomaniak/infomaniak"
      version = "1.4.1"
    }
  }
}

# Token is read from the INFOMANIAK_TOKEN environment variable.
provider "infomaniak" {}

resource "infomaniak_kaas" "cluster" {
  public_cloud_id         = var.public_cloud_id
  public_cloud_project_id = var.public_cloud_project_id

  name               = var.cluster_name
  pack_name          = "shared"
  kubernetes_version = var.kubernetes_version
  region             = var.region
}

resource "infomaniak_kaas_instance_pool" "workers" {
  public_cloud_id         = infomaniak_kaas.cluster.public_cloud_id
  public_cloud_project_id = infomaniak_kaas.cluster.public_cloud_project_id
  kaas_id                 = infomaniak_kaas.cluster.id

  name              = "workers"
  flavor_name       = var.worker_flavor
  availability_zone = var.availability_zone

  # min == max disables autoscaling
  min_instances = var.worker_count
  max_instances = var.worker_count
}

output "kubeconfig" {
  value     = infomaniak_kaas.cluster.kubeconfig
  sensitive = true
}
