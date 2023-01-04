module "subnet-cluster" {
  source      = "../../../modules/rds-subnets/"

  project_id   = "rds-rnd-project"
  network_name = "rds-vpc-dev"  
  subnets = [
    {
      subnet_name           = "subnet-sea1-cluster"
      subnet_ip             = "10.11.4.0/22"
      subnet_region         = "asia-southeast1"
    }   
  ]
  secondary_ranges = {
    subnet-sea1-cluster = [
      {
        range_name    = "subnet-sea1-cluster-pods"
        ip_cidr_range = "192.168.0.0/22"
      },
      {
        range_name    = "subnet-sea1-cluster-services-1"
        ip_cidr_range = "192.168.4.0/22"
      },
    ]
  }
}