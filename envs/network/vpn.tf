variable "home_cgw_ip" { type = string }  # your home router public IP
variable "home_bgp_asn" { type = number } # choose a private ASN, e.g., 65010

resource "aws_customer_gateway" "home" {
  ip_address = var.home_cgw_ip
  bgp_asn    = var.home_bgp_asn
  type       = "ipsec.1"
  tags       = { Name = "home-cgw" }
}

resource "aws_vpn_connection" "home" {
  customer_gateway_id = aws_customer_gateway.home.id
  transit_gateway_id  = module.tgw.tgw_id
  type                = "ipsec.1"
  static_routes_only  = false # set true if your router can't do BGP
  tags                = { Name = "tgw-vpn-home" }
}

# Associate VPN attachment to the 'vpn' TGW route table
resource "aws_ec2_transit_gateway_route_table_association" "assoc_vpn" {
  transit_gateway_attachment_id  = aws_vpn_connection.home.transit_gateway_attachment_id
  transit_gateway_route_table_id = module.tgw.rt_ids["vpn"]
}

# If using BGP (recommended): propagate routes between VPN and Dev
# resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_to_dev" {
#   transit_gateway_route_table_id = module.tgw.rt_ids["dev"]
#   transit_gateway_attachment_id  = aws_vpn_connection.home.transit_gateway_attachment_id
# }

# resource "aws_ec2_transit_gateway_route_table_propagation" "dev_to_vpn" {
#   transit_gateway_route_table_id = module.tgw.rt_ids["vpn"]
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment_accepter.dev.id
# }
