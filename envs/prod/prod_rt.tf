resource "aws_route" "prod_to_dev" {
  route_table_id         = module.vpc.private_route_table_id
  destination_cidr_block = "10.10.0.0/16" # DEV CIDR
  transit_gateway_id     = data.terraform_remote_state.network.outputs.tgw_id
}

resource "aws_route" "public_to_dev" {
  route_table_id         = module.vpc.public_route_table_id
  destination_cidr_block = "10.10.0.0/16"                      # DEV CIDR
  transit_gateway_id     = data.terraform_remote_state.network.outputs.tgw_id
}