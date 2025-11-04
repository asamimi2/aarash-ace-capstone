# Spoke RTs -> send other domains to INSPECTION attachment
resource "aws_ec2_transit_gateway_route" "dev_to_prod" {
  transit_gateway_route_table_id = module.tgw.rt_ids["dev"]
  destination_cidr_block         = var.prod_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspect.id
}
resource "aws_ec2_transit_gateway_route" "dev_to_home" {
  transit_gateway_route_table_id = module.tgw.rt_ids["dev"]
  destination_cidr_block         = var.home_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspect.id
}
resource "aws_ec2_transit_gateway_route" "prod_to_dev" {
  transit_gateway_route_table_id = module.tgw.rt_ids["prod"]
  destination_cidr_block         = var.dev_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspect.id
}
resource "aws_ec2_transit_gateway_route" "prod_to_home" {
  transit_gateway_route_table_id = module.tgw.rt_ids["prod"]
  destination_cidr_block         = var.home_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspect.id
}
resource "aws_ec2_transit_gateway_route" "home_to_dev" {
  transit_gateway_route_table_id = module.tgw.rt_ids["vpn"]
  destination_cidr_block         = var.dev_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspect.id
}
resource "aws_ec2_transit_gateway_route" "home_to_prod" {
  transit_gateway_route_table_id = module.tgw.rt_ids["vpn"]
  destination_cidr_block         = var.prod_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspect.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_to_inspect" {
  transit_gateway_route_table_id = module.tgw.rt_ids["inspect"]
  transit_gateway_attachment_id  = aws_vpn_connection.home.transit_gateway_attachment_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "dev_to_inspect" {
  transit_gateway_route_table_id = module.tgw.rt_ids["inspect"]
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment_accepter.dev.id
}

# INSPECT RT learns PROD prefixes
resource "aws_ec2_transit_gateway_route_table_propagation" "prod_to_inspect" {
  transit_gateway_route_table_id = module.tgw.rt_ids["inspect"]
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment_accepter.prod.id
}