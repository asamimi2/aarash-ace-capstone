data "terraform_remote_state" "network" {
  backend = "local"
  config  = { path = "../network/terraform.tfstate" }
}

module "vpc" {
  source                = "../../modules/vpc"
  name                  = "dev"
  cidr                  = "10.10.0.0/16"
  create_public_subnets = false
}

module "attach" {
  source         = "../../modules/tgw_attachment"
  vpc_id         = module.vpc.id
  subnet_ids     = module.vpc.tgw_subnet_ids
  tgw_id         = data.terraform_remote_state.network.outputs.tgw_id
  appliance_mode = true
}

output "dev_attachment_id" {
  value = module.attach.attachment_id
}
