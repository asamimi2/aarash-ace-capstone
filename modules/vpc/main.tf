data "aws_availability_zones" "az" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.name}-vpc" }
}

# Private subnets (for TGW attachment)
resource "aws_subnet" "private" {
  count                   = var.private_azs
  vpc_id                  = aws_vpc.this.id
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  cidr_block              = cidrsubnet(var.cidr, 8, count.index)
  map_public_ip_on_launch = false
  tags = { Name = "${var.name}-private-${count.index}" }
}

# Optional public subnets (for Prod ALB later)
resource "aws_subnet" "public" {
  count                   = var.create_public_subnets ? var.private_azs : 0
  vpc_id                  = aws_vpc.this.id
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  cidr_block              = cidrsubnet(var.cidr, 8, count.index + 100)
  map_public_ip_on_launch = true
  tags = { Name = "${var.name}-public-${count.index}" }
}

locals {
  private_subnet_ids = [for s in aws_subnet.private : s.id]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.name}-public-rt" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-private-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(local.private_subnet_ids)
  subnet_id      = local.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private.id
}