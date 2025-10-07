terraform {
  required_version = ">= 1.6.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
  backend "local" {}
}
provider "aws" {
  region  = "us-east-1"
  profile = "network-tf" # SSO profile for the Network account
  default_tags { tags = { ManagedBy = "Terraform", Environment = "network" } }
}