# ------------------------------------------------------------------------------
# LAUNCH A MYSQL CLUSTER WITH FAILOVER AND READ REPLICAS
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# CONFIGURE OUR GCP CONNECTION
# ------------------------------------------------------------------------------

# provider "google-beta" {
#   project = "rds-rnd-project"
#   region  = "asia-southeast1"
# }

terraform {
  required_version = ">= 0.12.26"

  # required_providers {
  #   google-beta = {
  #     source  = "hashicorp/google-beta"
  #     version = "~> 3.57.0"
  #   }
  # }
}

# ------------------------------------------------------------------------------
# CREATE A RANDOM SUFFIX AND PREPARE RESOURCE NAMES
# ------------------------------------------------------------------------------

resource "random_id" "name" {
  byte_length = 2
}

locals {
  # If name_override is specified, use that - otherwise use the name_prefix with a random string
  instance_name        = "cloud-sql-testing-1"
  private_network_name = "private-network-${random_id.name.hex}"
  private_ip_name      = "private-ip-${random_id.name.hex}"
}

# ------------------------------------------------------------------------------
# CREATE DATABASE CLUSTER WITH PUBLIC IP
# ------------------------------------------------------------------------------

module "mysql" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "github.com/gruntwork-io/terraform-google-sql.git//modules/cloud-sql?ref=v0.2.0"
  source = "../../../modules/rds-cloudsql"

  project = "rds-rnd-project"
  region  = "asia-southeast1"
  name    = local.instance_name
  db_name = "testing"

  engine       = "MYSQL_8_0"
  machine_type = "f1-micro"

  master_zone = "asia-southeast1-a"

  # To make it easier to test this example, we are giving the instances public IP addresses and allowing inbound
  # connections from anywhere. We also disable deletion protection so we can destroy the databases during the tests.
  # In real-world usage, your instances should live in private subnets, only have private IP addresses, and only allow
  # access from specific trusted networks, servers or applications in your VPC. By default, we recommend setting
  # deletion_protection to true, to ensure database instances are not inadvertently destroyed.
  enable_public_internet_access = true
  deletion_protection           = false

  authorized_networks = [
    {
      name  = "allow-all-inbound"
      value = "0.0.0.0/0"
    },
  ]

  # Indicate that we want to create a failover replica
  enable_failover_replica     = true
  mysql_failover_replica_zone = "asia-southeast1-b"

  # Indicate we want read replicas to be created
  num_read_replicas  = 1
  read_replica_zones = ["asia-southeast1-b", "asia-southeast1-c"]

  # These together will construct the master_user privileges, i.e.
  # 'master_user_name'@'master_user_host' IDENTIFIED BY 'master_user_password'.
  # These should typically be set as the environment variable TF_VAR_master_user_password, etc.
  # so you don't check these into source control."
  master_user_password = "rnd123123"

  master_user_name = "techno"
  master_user_host = "%"

  # Set auto-increment flags to test the
  # feature during automated testing
  database_flags = [
    {
      name  = "auto_increment_increment"
      value = "7"
    },
    {
      name  = "auto_increment_offset"
      value = "7"
    },
  ]

  custom_labels = {
    test-id = "mysql-replicas-example"
  }
}