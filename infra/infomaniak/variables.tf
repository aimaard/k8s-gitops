variable "public_cloud_id" {
  type = number
}

variable "public_cloud_project_id" {
  type = number
}

variable "cluster_name" {
  type    = string
  default = "ysi"
}

variable "kubernetes_version" {
  type    = string
  default = "1.37"
}

variable "region" {
  type    = string
  default = "dc4-a"
}

variable "availability_zone" {
  type    = string
  default = "az-2"
}

variable "worker_flavor" {
  type    = string
  default = "a4-ram8-disk20-perf1"
}

variable "worker_count" {
  type    = number
  default = 2
}
