data "google_compute_network" "host_network" {
  name    = var.host_network
  project = var.host_project
}

data "google_compute_subnetwork" "gke_subnetwork" {
  provider = google
  name     = var.subnet
  region   = var.subnet_region
  project  = var.host_project
}

resource "google_service_account" "service_account" {
  project    = var.service_project
  account_id = var.cluster_name
}

locals {

  app_pool_names = [for ap in toset(var.app_pools) : ap.name]
  app_pools      = zipmap(local.app_pool_names, tolist(toset(var.app_pools)))

  nat_pool_names = [for np in toset(var.nat_pools) : np.name]
  nat_pools      = zipmap(local.nat_pool_names, tolist(toset(var.nat_pools)))

  all_service_account_roles = concat([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/storage.objectViewer",
    "roles/artifactregistry.reader",
    "roles/cloudkms.cryptoKeyDecrypter",
    "roles/cloudkms.cryptoKeyEncrypter",
    "roles/cloudkms.cryptoKeyVersions.useToDecrypt",
    "roles/cloudkms.cryptoKeyVersions.useToEncrypt"
  ])
}

resource "google_project_iam_member" "service_account-roles" {
  for_each = toset(local.all_service_account_roles)

  project = var.service_project
  role    = each.value
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

data "google_project" "service_project" {
  project_id = var.service_project
}

resource "google_container_cluster" "primary" {
  provider = google-beta
  name     = var.cluster_name
  project  = var.service_project
  location = var.cluster_location
  network    = var.host_project
  subnetwork = var.subnet
  

  remove_default_node_pool    = true
  initial_node_count          = 1
  enable_binary_authorization = var.enable_binary_authorization

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  default_max_pods_per_node = 30

  enable_shielded_nodes = true

  release_channel {
    channel = "UNSPECIFIED"
  }

  min_master_version = var.min_master_version

  addons_config {
    dns_cache_config {
      enabled = true
    }
  }

  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    services_secondary_range_name = var.services_range
    cluster_secondary_range_name  = var.pods_range
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All"
    }
  }

  database_encryption {
    state    = "ENCRYPTED"
    key_name = "projects/${var.service_project}/locations/${var.cluster_location}/keyRings/${var.cluster_name}-secrets/cryptoKeys/${var.cluster_name}-secret"
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "19:00"
    }
  }

  network_policy {
    provider = "CALICO"
    enabled  = true
  }

  pod_security_policy_config {
    enabled = var.pod_security_policy
  }

  vertical_pod_autoscaling {
    enabled = var.vertical_pod_autoscaling
  }

  workload_identity_config {
    identity_namespace = "${var.service_project}.svc.id.goog"
  }

  # dynamic cluster_autoscaling {
  #   for_each = var.cluster_autoscaling == true ? [1] : [0]
  #   content {
  #     enabled = true
  #     resource_limits {
  #       resource_type = "cpu"
  #       maximum       = var.max_cpu
  #     }
  #     resource_limits {
  #       resource_type = "memory"
  #       maximum       = var.max_memory        
  #     }
  #   }
  # }

  cluster_autoscaling {
    enabled = var.cluster_autoscaling

    # dynamic "resource_limits" {
    #   for_each = var.cluster_autoscaling == true ? [1] : []
    #   content {
    #     resource_type = "cpu"
    #     maximum       = var.max_cpu
    #   }
    # }

    # dynamic "resource_limits" {
    #   for_each = var.cluster_autoscaling == true ? [1] : [0]
    #   content {
    #     resource_type = "memory"
    #     maximum       = var.max_memory
    #   }
    # }
    # resource_limits {
    #   resource_type = "cpu"
    #   maximum       = var.max_cpu
    # }
    # resource_limits {
    #   resource_type = "memory"
    #   maximum       = var.max_memory
    # }
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_range
  }

  # master_auth {
  #   username = ""
  #   password = ""

  #   client_certificate_config {
  #     issue_client_certificate = false
  #   }
  # }
  timeouts {
    create = "30m"
    update = "40m"
  }
}

resource "google_container_node_pool" "nat_pool" {
  provider = google-beta
  for_each = local.nat_pools
  name     = each.key
  location = var.cluster_location
  project  = var.service_project

  cluster = google_container_cluster.primary.name

  management {
    auto_repair  = true
    auto_upgrade = var.nodepool_auto_upgrade
  }

  initial_node_count = lookup(each.value, "initial_node_count_nat_pool", 1)
  autoscaling {
    min_node_count = lookup(each.value, "min_node_count_nat_pool", 1)
    max_node_count = lookup(each.value, "max_node_count_nat_pool", 100)
  }

  node_config {
    preemptible = lookup(each.value, "preemtible", false)
    image_type  = lookup(each.value, "image_type", "COS")

    machine_type    = lookup(each.value, "machine_type", "n1-standard-1")

    service_account = google_service_account.service_account.email

    disk_size_gb    = lookup(each.value, "disk_size_gb", 100)
    disk_type       = lookup(each.value, "disk_type", "pd-standard")

    metadata = {
      disable-legacy-endpoints = "true"
    }

    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }

    tags = [
      lookup(each.value, "nat_tags", "")
    ]

    labels = {
      nat = lookup(each.value, "taint_label", "")
      whitelist = "yes"
    }
    taint = [
      {
        effect = "NO_SCHEDULE"
        key    = "nat"
        value  = lookup(each.value, "taint_label", "")
    }]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

}

resource "google_container_node_pool" "pool" {
  provider = google-beta
  for_each = local.app_pools
  name     = each.key
  location = var.cluster_location
  project  = var.service_project

  cluster = google_container_cluster.primary.name

  management {
    auto_repair  = true
    auto_upgrade = var.nodepool_auto_upgrade
  }

  initial_node_count = lookup(each.value, "initial_node_count_pool", 1)
  autoscaling {
    min_node_count = lookup(each.value, "min_node_count_pool", 1)
    max_node_count = lookup(each.value, "max_node_count_pool", 5)
  }

  node_config {
    preemptible = lookup(each.value, "preemtible", false)
    image_type  = lookup(each.value, "image_type", "COS")

    machine_type    = lookup(each.value, "machine_type", "n1-standard-1")
    service_account = google_service_account.service_account.email

    disk_size_gb    = lookup(each.value, "disk_size_gb", 20)
    disk_type       = lookup(each.value, "disk_type", "pd-standard")

    metadata = {
      disable-legacy-endpoints = "true"
    }

    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }

    tags = []

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

}

output "api_ip_addr" {
  value = google_container_cluster.primary.endpoint
}
