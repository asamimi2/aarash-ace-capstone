resource "aws_security_group" "alb" {
  name   = "prod-alb-sg"
  vpc_id = module.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "prod-alb-sg" }
}

resource "aws_lb" "web" {
  name               = "prod-web-alb"
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]
  idle_timeout       = 60
  tags               = { Name = "prod-web-alb" }
}

resource "aws_lb_target_group" "web" {
  name     = "prod-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.id
  health_check {
    protocol = "HTTP"
    path     = "/"
    matcher  = "200-399"
  }
  tags = { Name = "prod-web-tg" }
}

resource "aws_lb_target_group_attachment" "web_instance" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.prod_web.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_wafv2_web_acl" "web" {
  name  = "prod-web-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "prod-web-waf"
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

resource "aws_wafv2_web_acl_association" "alb_assoc" {
  resource_arn = aws_lb.web.arn
  web_acl_arn  = aws_wafv2_web_acl.web.arn
}

resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-prod-web-waf"
  retention_in_days = 30
  tags              = { App = "prod-web" }
}

resource "aws_wafv2_web_acl_logging_configuration" "waf_to_cwl" {
  resource_arn            = aws_wafv2_web_acl.web.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]

  redacted_fields {
    single_header { name = "authorization" }
  }
}
