terraform {
  backend "gcs" {
    bucket = "tf-remote-state-rds"
    prefix = "vpc/state"
  }
}
