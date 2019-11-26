provider "aws" {
  version = "~> 2.39"
  region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket = "re-dup-tf-backend"
    key = "redup/terraform.tfstate"
    region = "us-east-2"
  }
}