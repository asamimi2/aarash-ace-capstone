resource "aws_ec2_transit_gateway" "this" {
  amazon_side_asn                 = var.asn
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"
  tags = { Name = "capstone-tgw" }
}

# ONLY two route tables now
resource "aws_ec2_transit_gateway_route_table" "rt" {
  for_each           = toset(["spoke","inspect"])
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags = {
    Name = "tgw-rt-${each.key}"   # tgw-rt-spoke, tgw-rt-inspect
    Role = "tgw-rt-${each.key}"
  }
}
