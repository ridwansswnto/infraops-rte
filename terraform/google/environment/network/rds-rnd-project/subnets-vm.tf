module "subnet-vm" {
  source      = "../../../modules/rds-subnets/"

  project_id   = "rds-rnd-project"
  network_name = "rds-vpc-dev"  
  subnets = [
    {
      subnet_name           = "subnet-sea1-app-int"
      subnet_ip             = "10.11.1.0/24"
      subnet_region         = "asia-southeast1"
    },
    {
      subnet_name           = "subnet-sea1-app-ext"
      subnet_ip             = "10.11.2.0/24"
      subnet_region         = "asia-southeast1"
    },
    {
      subnet_name           = "subnet-sea1-db"
      subnet_ip             = "10.11.3.0/24"
      subnet_region         = "asia-southeast1"
    } 
  ]
}