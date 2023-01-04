variable "host_project" {
  type = string
}

variable "host_network" {
  type = string
}

variable "service_project" {
  type = string
}

variable "subnet" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_location" {
  type = string
}

variable "regional_cluster" {
  default = true
}

variable "services_range" {
  type = string
}

variable "pods_range" {
  type = string
}

variable "master_range" {
  type = string
}

variable "subnet_region" {
  type = string
}

variable "enable_binary_authorization" {
  type    = bool
  default = false
}

variable "nodepool_auto_upgrade" {
  type    = bool
  default = false
}

variable "max_cpu" {
  type    = string
}

variable "max_memory" {
  type    = string
}

variable "app_pools" {
  type = list(map(string))
}

variable "nat_pools" {
  type = list(map(string))
  default = []
}

variable "pod_security_policy" {
  type    = bool
  default = true
}

variable "vertical_pod_autoscaling" {
  type    = bool
  default = false
}

variable "autoscaling_profile" {
  type    = string
  default = "BALANCED"
}

variable "min_master_version" {
  type    = string
  default = "1.24.5-gke.600"
}

variable "initial_node_count_pool" {
  type    = number
  default = 1
}

variable "min_node_count_pool" {
  type    = number
  default = 1
}

variable "max_node_count_pool" {
  type    = number
  default = 100
}

variable "initial_node_count_nat_pool" {
  type    = number
  default = 1
}

variable "min_node_count_nat_pool" {
  type    = number
  default = 1
}

variable "max_node_count_nat_pool" {
  type    = number
  default = 100
}