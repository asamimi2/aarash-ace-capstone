data "terraform_remote_state" "network" {
  backend = "local"
  config  = { path = "../network/terraform.tfstate" }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"] # Amazon
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

module "vpc" {
  source                = "../../modules/vpc"
  name                  = "prod"
  cidr                  = "10.20.0.0/16" # <— hard-coded
  create_public_subnets = true           # public subnets for ALB later
}

module "attach" {
  source         = "../../modules/tgw_attachment"
  vpc_id         = module.vpc.id
  subnet_ids     = module.vpc.tgw_subnet_ids
  tgw_id         = data.terraform_remote_state.network.outputs.tgw_id
  appliance_mode = true
}

output "prod_attachment_id" {
  value = module.attach.attachment_id
}

# Create and attach an Internet Gateway
resource "aws_internet_gateway" "prod_igw" {
  vpc_id = module.vpc.id
  tags = {
    Name = "prod-igw"
  }
}

# Update public route table for Internet access
resource "aws_route" "public_internet" {
  route_table_id         = module.vpc.public_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.prod_igw.id
}

# Security Group
resource "aws_security_group" "prod_web_sg" {
  name   = "prod-web-sg"
  vpc_id = module.vpc.id

  # HTTP from ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # (optional) ping from Dev
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "prod-web-sg" }
}

# IAM Role for SSM
resource "aws_iam_role" "prod_ssm_role" {
  name = "prod-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "prod_ssm_attach" {
  role       = aws_iam_role.prod_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "prod_ssm_profile" {
  name = "prod-ssm-profile"
  role = aws_iam_role.prod_ssm_role.name
}

# EC2 instance (public)
resource "aws_instance" "prod_web" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = "t3.micro"
  subnet_id            = module.vpc.private_subnet_ids[0]   # was public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.prod_web_sg.id]
  iam_instance_profile = aws_iam_instance_profile.prod_ssm_profile.name

  associate_public_ip_address = false                       # was true

  user_data_replace_on_change = true
  user_data = <<-EOF
#!/bin/bash
set -euxo pipefail
PKG=dnf; command -v dnf >/dev/null 2>&1 || PKG=yum
$PKG -y install httpd || true
systemctl enable --now httpd || true
echo "Hello from PROD $(hostname -f)" > /var/www/html/index.html
systemctl enable --now amazon-ssm-agent || true
EOF

  tags = { Name = "prod-web" }
}
