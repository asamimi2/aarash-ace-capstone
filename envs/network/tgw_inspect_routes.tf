# SPOKE RT: send Dev and Customer prefixes to the INSPECTION attachment
resource "aws_ec2_transit_gateway_route" "spoke_to_dev" {
  transit_gateway_route_table_id = module.tgw.rt_ids["spoke"]
  destination_cidr_block         = var.dev_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspect.id
}

resource "aws_ec2_transit_gateway_route" "spoke_to_customer" {
  for_each                       = toset(var.customer_lans) # ["192.168.69.0/24"]
  transit_gateway_route_table_id = module.tgw.rt_ids["spoke"]
  destination_cidr_block         = each.value
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspect.id
}

# INSPECT RT: propagate only the attachments that must return traffic
resource "aws_ec2_transit_gateway_route_table_propagation" "dev_to_inspect" {
  transit_gateway_route_table_id = module.tgw.rt_ids["inspect"]
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment_accepter.dev.id
}
resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_to_inspect" {
  transit_gateway_route_table_id = module.tgw.rt_ids["inspect"]
  transit_gateway_attachment_id  = aws_vpn_connection.customer.transit_gateway_attachment_id
}

# (Optional) if you still associate Prod to SPOKE for internal AWS east-west,
# you can propagate Prod into INSPECT as well:
# resource "aws_ec2_transit_gateway_route_table_propagation" "prod_to_inspect" {
#   transit_gateway_route_table_id = module.tgw.rt_ids["inspect"]
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment_accepter.prod.id
# }

# INSPECT RT: send Dev back to the Dev attachment
resource "aws_ec2_transit_gateway_route" "inspect_to_dev" {
  transit_gateway_route_table_id = module.tgw.rt_ids["inspect"]
  destination_cidr_block         = var.dev_cidr # 10.10.0.0/16
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment_accepter.dev.id
}

# INSPECT RT: send Customer LANs back to the VPN attachment
resource "aws_ec2_transit_gateway_route" "inspect_to_customer" {
  for_each                       = toset(var.customer_lans) # ["192.168.69.0/24"]
  transit_gateway_route_table_id = module.tgw.rt_ids["inspect"]
  destination_cidr_block         = each.value
  transit_gateway_attachment_id  = aws_vpn_connection.customer.transit_gateway_attachment_id
}

resource "aws_ec2_transit_gateway_route" "spoke_to_prod" {
  transit_gateway_route_table_id = module.tgw.rt_ids["spoke"]
  destination_cidr_block         = var.prod_cidr # 10.20.0.0/16
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspect.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "prod_to_inspect" {
  transit_gateway_route_table_id = module.tgw.rt_ids["inspect"]
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment_accepter.prod.id
}
