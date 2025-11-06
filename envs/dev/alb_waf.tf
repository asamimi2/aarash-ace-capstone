# --- Security group for the ALB (private) ---
resource "aws_security_group" "dev_alb" {
  name   = "dev-alb-sg"
  vpc_id = module.vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["10.20.0.0/16", "192.168.69.0/24", "10.10.0.0/16"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "dev-alb-sg" }
}

resource "aws_lb" "dev_web" {
  name               = "dev-web-alb"
  load_balancer_type = "application"
  internal           = true
  subnets            = module.vpc.private_subnet_ids
  security_groups    = [aws_security_group.dev_alb.id]
  idle_timeout       = 60
  tags               = { Name = "dev-web-alb" }
}

resource "aws_lb_target_group" "dev_web" {
  name     = "dev-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.id

  health_check {
    protocol = "HTTP"
    path     = "/"
    matcher  = "200-399"
  }

  tags = { Name = "dev-web-tg" }
}

resource "aws_lb_target_group_attachment" "dev_web_instance" {
  target_group_arn = aws_lb_target_group.dev_web.arn
  target_id        = aws_instance.dev_web.id
  port             = 80
}

resource "aws_lb_listener" "dev_http" {
  load_balancer_arn = aws_lb.dev_web.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dev_web.arn
  }
}

resource "aws_wafv2_web_acl" "dev_web" {
  name  = "dev-web-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "dev-web-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedCommon"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedKnownBadInputs"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputs"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_association" "dev_alb_assoc" {
  resource_arn = aws_lb.dev_web.arn
  web_acl_arn  = aws_wafv2_web_acl.dev_web.arn
}

resource "aws_cloudwatch_log_group" "dev_waf" {
  name              = "aws-waf-logs-dev-web-waf"
  retention_in_days = 30
  tags              = { App = "dev-web" }
}

resource "aws_wafv2_web_acl_logging_configuration" "dev_waf_to_cwl" {
  resource_arn            = aws_wafv2_web_acl.dev_web.arn
  log_destination_configs = [aws_cloudwatch_log_group.dev_waf.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}
