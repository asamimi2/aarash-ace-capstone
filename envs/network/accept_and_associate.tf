# Read the attachment IDs that Dev/Prod just created
data "terraform_remote_state" "dev" {
  backend = "local"
  config  = { path = "../dev/terraform.tfstate" }
}

data "terraform_remote_state" "prod" {
  backend = "local"
  config  = { path = "../prod/terraform.tfstate" }
}

# Accept the cross-account attachments (TGW owner = Network account)
resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "dev" {
  transit_gateway_attachment_id = data.terraform_remote_state.dev.outputs.dev_attachment_id
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "prod" {
  transit_gateway_attachment_id = data.terraform_remote_state.prod.outputs.prod_attachment_id
}

# Associate each attachment to its dedicated TGW route table
resource "aws_ec2_transit_gateway_route_table_association" "assoc_dev" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment_accepter.dev.id
  transit_gateway_route_table_id = module.tgw.rt_ids["dev"]
}

resource "aws_ec2_transit_gateway_route_table_association" "assoc_prod" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment_accepter.prod.id
  transit_gateway_route_table_id = module.tgw.rt_ids["prod"]
}
