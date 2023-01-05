terraform {
  required_version = "> 0.14"
  required_providers {
    google      = "~> 3.10"
    google-beta = "~> 3.10"
  }
  backend "gcs" {
    bucket = "tf-remote-state-rds"
    prefix = "gke/state"
  }
}

provider "google" {
  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

provider "google-beta" {
  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

data "google_client_config" "client" {}
data "google_client_openid_userinfo" "terraform_user" {}

module "ta-cryptokey" {
  source = "../../modules/rds-crypto"
  service_project  = "rds-rnd-project"
  cluster_name     = "rnd-cluster"
  cluster_location = "asia-southeast1"
}

# CLUSTER
module "rds-cluster" {
  source = "../../modules/rds-gke"
  host_project                = "rds-vpc-dev"
  host_network                = "rds-rnd-project"
  service_project             = "rds-rnd-project"
  subnet                      = "subnet-sea1-cluster"
  subnet_region               = "asia-southeast1"
  region                      = "asia-southeast1"
  cluster_name                = "rnd-cluster"
  cluster_location            = "asia-southeast1"
  pods_range                  = "subnet-sea1-cluster-pods"
  services_range              = "subnet-sea1-cluster-services-1"
  master_range                = "192.168.190.160/28"
  max_cpu                     = 100
  max_memory                  = 200
  enable_binary_authorization = true
  nodepool_auto_upgrade       = false
  cluster_autoscaling         = true

  #APP POOL
  app_pools                   = [
    {
      name                    = "app-pool"
      machine_type            = "custom-2-${2 * 1024}"
      image_type              = "COS_CONTAINERD"
      preemtible              = true
    },
  ]

}
