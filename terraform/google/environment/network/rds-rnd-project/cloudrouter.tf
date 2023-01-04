module "cloud_router" {
  source      = "../../../modules/rds-cloudnat/"

  project_id   = "rds-rnd-project"
  network       = module.vpc.network_name 
  region        = "asia-southeast1"
  create_router = true
  router        = "ta-sea1-nat-router"
  name          = "ta-sea1-nat"
}