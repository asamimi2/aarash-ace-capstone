resource "aws_route" "dev_to_prod" {
  route_table_id         = module.vpc.private_route_table_id
  destination_cidr_block = "10.20.0.0/16" # PROD CIDR
  transit_gateway_id     = data.terraform_remote_state.network.outputs.tgw_id
}

resource "aws_route" "home_via_tgw" {
  route_table_id         = module.vpc.private_route_table_id
  destination_cidr_block = "192.168.0.0/16"
  transit_gateway_id     = data.terraform_remote_state.network.outputs.tgw_id
}
