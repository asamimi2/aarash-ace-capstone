data "aws_region" "current" {}

# SG for the endpoint ENIs: allow HTTPS from *your prod instances*
resource "aws_security_group" "prod_vpce_sg" {
  name        = "prod-vpce-sg"
  description = "Allow HTTPS from Prod instances to SSM endpoints"
  vpc_id      = module.vpc.id

  # Most precise: source is the instance SG
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.prod_web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "prod-vpce-sg" }
}

# Interface endpoints in *PROD VPC* and *private subnets*
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.prod_vpce_sg.id]
  private_dns_enabled = true
  tags                = { Name = "prod-ssm-vpce" }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = module.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.prod_vpce_sg.id]
  private_dns_enabled = true
  tags                = { Name = "prod-ssmmessages-vpce" }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = module.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.prod_vpce_sg.id]
  private_dns_enabled = true
  tags                = { Name = "prod-ec2messages-vpce" }
}
