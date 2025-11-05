variable "home_cgw_ip" { type = string }  # your home router public IP
variable "home_bgp_asn" { type = number } # choose a private ASN, e.g., 65010

resource "aws_customer_gateway" "customer" {
  ip_address = var.customer_cgw_ip  # 66.25.103.244
  bgp_asn    = var.customer_bgp_asn # required field even if static
  type       = "ipsec.1"
  tags       = { Name = "customer-pfsense" }
}

resource "aws_vpn_connection" "customer" {
  customer_gateway_id = aws_customer_gateway.customer.id
  transit_gateway_id  = module.tgw.tgw_id
  type                = "ipsec.1"
  static_routes_only  = true # STATIC
  tags                = { Name = "tgw-vpn-customer" }
}