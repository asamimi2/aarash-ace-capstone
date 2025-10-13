data "terraform_remote_state" "network" {
  backend = "local"
  config  = { path = "../network/terraform.tfstate" }
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
  appliance_mode = true
}

output "dev_attachment_id" {
  value = module.attach.attachment_id
}

# Security Group
resource "aws_security_group" "dev_web_sg" {
  name   = "dev-web-sg"
  vpc_id = module.vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"] # allow only from Prod CIDR
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.20.0.0/16"]
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
  ami                    = "ami-0c7217cdde317cfec" # Amazon Linux 2
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.dev_web_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.dev_ssm_profile.name
  user_data              = <<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from DEV Web Server" > /var/www/html/index.html
              EOF
  tags                   = { Name = "dev-web" }
}
