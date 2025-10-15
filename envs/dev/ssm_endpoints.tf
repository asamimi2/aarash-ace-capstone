data "aws_region" "current" {}

resource "aws_security_group" "dev_vpce_sg" {
  name        = "dev-vpce-sg"
  description = "Allow HTTPS from Dev VPC to SSM endpoints"
  vpc_id      = module.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "dev-vpce-sg" }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.dev_vpce_sg.id]
  private_dns_enabled = true
  tags                = { Name = "dev-ssm-vpce" }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = module.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.dev_vpce_sg.id]
  private_dns_enabled = true
  tags                = { Name = "dev-ssmmessages-vpce" }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = module.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.dev_vpce_sg.id]
  private_dns_enabled = true
  tags                = { Name = "dev-ec2messages-vpce" }
}
