# Look up accepted attachments by the accepter resources you already created
data "aws_ec2_transit_gateway_vpc_attachment" "dev" {
  id = aws_ec2_transit_gateway_vpc_attachment_accepter.dev.id
}

data "aws_ec2_transit_gateway_vpc_attachment" "prod" {
  id = aws_ec2_transit_gateway_vpc_attachment_accepter.prod.id
}

# Let the PROD attachment propagate into the DEV RT
resource "aws_ec2_transit_gateway_route_table_propagation" "prod_into_dev" {
  transit_gateway_route_table_id = module.tgw.rt_ids["dev"]
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpc_attachment.prod.id
}

# Let the DEV attachment propagate into the PROD RT
resource "aws_ec2_transit_gateway_route_table_propagation" "dev_into_prod" {
  transit_gateway_route_table_id = module.tgw.rt_ids["prod"]
  transit_gateway_attachment_id  = data.aws_ec2_transit_gateway_vpc_attachment.dev.id
}