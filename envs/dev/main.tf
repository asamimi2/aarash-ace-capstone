data "terraform_remote_state" "network" {
  backend = "local"
  config  = { path = "../network/terraform.tfstate" }
}

data "aws_ami" "al2" {
  most_recent = true
  owners      = ["137112412989"] # Amazon
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }
}

module "vpc" {
  source                = "../../modules/vpc"
  name                  = "dev"
  cidr                  = "10.10.0.0/16"
  create_public_subnets = false
}

module "attach" {
  source         = "../../modules/tgw_attachment"
  vpc_id         = module.vpc.id
  subnet_ids     = module.vpc.tgw_subnet_ids
  tgw_id         = data.terraform_remote_state.network.outputs.tgw_id
  appliance_mode = false
}

output "dev_attachment_id" {
  value = module.attach.attachment_id
}

# Security Group
resource "aws_security_group" "dev_web_sg" {
  name   = "dev-web-sg"
  vpc_id = module.vpc.id
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.20.0.0/16"]
  }
  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = ["192.168.69.0/24"]
  }
  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.dev_alb.id] # only ALB can reach the instance on :80
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "dev-web-sg" }
}

# IAM Role for SSM
resource "aws_iam_role" "dev_ssm_role" {
  name = "dev-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "dev_ssm_attach" {
  role       = aws_iam_role.dev_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "dev_ssm_profile" {
  name = "dev-ssm-profile"
  role = aws_iam_role.dev_ssm_role.name
}

# EC2 instance (private)

resource "aws_instance" "dev_web" {
  ami                         = data.aws_ami.al2.id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.dev_web_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.dev_ssm_profile.name
  associate_public_ip_address = false

  # No package installs (no Internet). You can add your app later via VPN.
  user_data_replace_on_change = true
  user_data                   = <<-EOF
#!/bin/bash
set -euxo pipefail

# Put a simple page
mkdir -p /var/www/html
echo "Hello from DEV $(hostname -f)" > /var/www/html/index.html

# Start a tiny web server on :80 without needing yum/dnf
if command -v python3 >/dev/null 2>&1; then
  nohup python3 -m http.server 80 --directory /var/www/html >/var/log/web.log 2>&1 &
elif command -v busybox >/dev/null 2>&1; then
  nohup busybox httpd -f -p 80 -h /var/www/html >/var/log/web.log 2>&1 &
else
  # If neither tool exists on your AMI, we can switch to an S3 endpoint approach.
  echo "No python3 or busybox found; cannot start web server" >&2
  exit 1
fi

# Make sure SSM agent is running (AL2 usually has it)
systemctl enable --now amazon-ssm-agent || true
EOF
  tags                        = { Name = "dev-web" }
}