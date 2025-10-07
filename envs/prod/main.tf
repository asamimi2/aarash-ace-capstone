data "terraform_remote_state" "network" {
  backend = "local"
  config  = { path = "../network/terraform.tfstate" }
}

module "vpc" {
  source                = "../../modules/vpc"
  name                  = "prod"
  cidr                  = "10.20.0.0/16" # <— hard-coded
  create_public_subnets = true           # public subnets for ALB later
}

module "attach" {
  source         = "../../modules/tgw_attachment"
  vpc_id         = module.vpc.id
  subnet_ids     = module.vpc.tgw_subnet_ids
  tgw_id         = data.terraform_remote_state.network.outputs.tgw_id
  appliance_mode = true
}

output "prod_attachment_id" {
  value = module.attach.attachment_id
}
