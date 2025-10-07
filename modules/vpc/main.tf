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
