resource "aws_vpc" "inspect" {
  cidr_block           = var.inspection_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "inspection-vpc" }
}

# TGW-facing subnets (one per AZ)
resource "aws_subnet" "tgw_az" {
  for_each          = toset(var.azs)
  vpc_id            = aws_vpc.inspect.id
  cidr_block        = cidrsubnet(var.inspection_vpc_cidr, 4, index(var.azs, each.key))
  availability_zone = each.key
  tags              = { Name = "inspect-tgw-${each.key}" }
}

# Firewall endpoint subnets (one per AZ)
resource "aws_subnet" "fw_az" {
  for_each          = toset(var.azs)
  vpc_id            = aws_vpc.inspect.id
  cidr_block        = cidrsubnet(var.inspection_vpc_cidr, 4, 8 + index(var.azs, each.key))
  availability_zone = each.key
  tags              = { Name = "inspect-fw-${each.key}" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "inspect" {
  vpc_id             = aws_vpc.inspect.id
  subnet_ids         = [for s in aws_subnet.tgw_az : s.id]
  transit_gateway_id = module.tgw.tgw_id

  appliance_mode_support = "enable"
  tags                   = { Name = "tgw-attach-inspection" }
}