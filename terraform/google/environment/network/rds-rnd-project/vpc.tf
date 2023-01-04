module "vpc" {
  source      = "../../../modules/rds-vpc/"

  project_id   = "rds-rnd-project"
  network_name = "rds-vpc-dev"
  routing_mode = "REGIONAL"
  mtu          = 1460

  shared_vpc_host = false
}