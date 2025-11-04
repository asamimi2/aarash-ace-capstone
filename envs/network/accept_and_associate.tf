# Read the attachment IDs that Dev/Prod just created
data "terraform_remote_state" "dev" {
  backend = "local"
  config  = { path = "../dev/terraform.tfstate" }
}

data "terraform_remote_state" "prod" {
  backend = "local"
  config  = { path = "../prod/terraform.tfstate" }
}

# accepters (keep as is, just shown for context)
resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "dev" {
  transit_gateway_attachment_id                   = data.terraform_remote_state.dev.outputs.dev_attachment_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}
resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "prod" {
  transit_gateway_attachment_id                   = data.terraform_remote_state.prod.outputs.prod_attachment_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

# NEW: SPOKE associations (Dev + VPN to SPOKE)
resource "aws_ec2_transit_gateway_route_table_association" "assoc_dev" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment_accepter.dev.id
  transit_gateway_route_table_id = module.tgw.rt_ids["spoke"]
}

resource "aws_ec2_transit_gateway_route_table_association" "assoc_vpn" {
  transit_gateway_attachment_id  = aws_vpn_connection.customer.transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.rt_ids["spoke"]
}

# INSPECT association (inspection VPC stays on INSPECT)
resource "aws_ec2_transit_gateway_route_table_association" "assoc_inspect" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspect.id
  transit_gateway_route_table_id = module.tgw.rt_ids["inspect"]
}

resource "aws_ec2_transit_gateway_route_table_association" "assoc_prod" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment_accepter.prod.id
  transit_gateway_route_table_id = module.tgw.rt_ids["spoke"]
}
