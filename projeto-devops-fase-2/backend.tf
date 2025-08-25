terraform {
  backend "s3" {
    bucket  = "testing-s3-state-terraform"
    key     = "site/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}