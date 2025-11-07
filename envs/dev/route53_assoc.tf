# envs/dev/route53_assoc.tf
data "terraform_remote_state" "shared" {
  backend = "local"
  config  = { path = "../shared/terraform.tfstate" }
}

resource "aws_route53_zone_association" "dev_assoc" {
  zone_id = data.terraform_remote_state.shared.outputs.shared_internal_zone_id
  vpc_id  = module.vpc.id
  vpc_region = "us-east-1"
}