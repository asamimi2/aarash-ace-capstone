resource "aws_ec2_transit_gateway" "this" {
  amazon_side_asn                 = var.asn
  default_route_table_association = "disable"   # was: false
  default_route_table_propagation = "disable"   # was: false
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"    # optional, fine to keep
}

resource "aws_ec2_transit_gateway_route_table" "rt" {
  for_each           = toset(["dev","prod","inspect","vpn"])
  transit_gateway_id = aws_ec2_transit_gateway.this.id
}
