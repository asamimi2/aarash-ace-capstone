data "terraform_remote_state" "network" {
  backend = "local"
  config  = { path = "../network/terraform.tfstate" }
}

# Route Home CIDR to TGW on the private route table
resource "aws_route" "home_via_tgw" {
  route_table_id         = module.vpc.private_route_table_id
  destination_cidr_block = "192.168.0.0/16"   # <-- your real home CIDR
  transit_gateway_id     = data.terraform_remote_state.network.outputs.tgw_id
}
