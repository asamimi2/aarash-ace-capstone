# Map each AZ -> its NFW endpoint ID (computed after firewall is created)
locals {
  nfw_endpoints_by_az = {
    for st in aws_networkfirewall_firewall.this.firewall_status[0].sync_states :
    st.availability_zone => st.attachment[0].endpoint_id
  }
}

# TGW subnet RTs: default -> AZ-local NFW endpoint
resource "aws_route_table" "tgw_rt" {
  for_each = aws_subnet.tgw_az
  vpc_id   = aws_vpc.inspect.id
  tags     = { Name = "rt-inspect-tgw-${each.key}" }
}

resource "aws_route_table_association" "tgw_assoc" {
  for_each       = aws_subnet.tgw_az
  subnet_id      = each.value.id
  route_table_id = aws_route_table.tgw_rt[each.key].id
}

resource "aws_route" "tgw_to_nfw_default" {
  for_each               = toset(var.azs)  # e.g., ["us-east-1a","us-east-1b"]
  route_table_id         = aws_route_table.tgw_rt[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.nfw_endpoints_by_az[each.key]

  depends_on = [
    aws_networkfirewall_firewall.this,
    aws_route_table.tgw_rt
  ]
}

# Firewall subnet RTs: default -> TGW
resource "aws_route_table" "fw_rt" {
  for_each = aws_subnet.fw_az
  vpc_id   = aws_vpc.inspect.id
  tags     = { Name = "rt-inspect-fw-${each.key}" }
}

resource "aws_route_table_association" "fw_assoc" {
  for_each       = aws_subnet.fw_az
  subnet_id      = each.value.id
  route_table_id = aws_route_table.fw_rt[each.key].id
}

resource "aws_route" "fw_to_tgw_default" {
  for_each               = aws_subnet.fw_az
  route_table_id         = aws_route_table.fw_rt[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.tgw.tgw_id
}
