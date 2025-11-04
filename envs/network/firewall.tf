resource "aws_networkfirewall_rule_group" "stateful_ip_allow" {
  capacity = 100
  name     = "nfw-allow-cidrs"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_string = <<-EOT
        pass ip ${var.dev_cidr} any -> 192.168.69.0/24 any (sid:1101;)
        pass ip 192.168.69.0/24 any -> ${var.dev_cidr} any (sid:1102;)
        pass ip ${var.dev_cidr} any -> ${var.prod_cidr} any (sid:1201;)
        pass ip ${var.prod_cidr} any -> ${var.dev_cidr} any (sid:1202;)
        drop ip any any -> any any (sid:2000; msg:"Default drop";)
      EOT
    }
  }

  tags = { Name = "nfw-allow-cidrs" }
}

resource "aws_networkfirewall_firewall_policy" "policy" {
  name = "nfw-policy-e2w"

  firewall_policy {
    # Use default order; do NOT set stateful_default_actions here
    stateful_engine_options { rule_order = "DEFAULT_ACTION_ORDER" }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful_ip_allow.arn
      # no priority needed with DEFAULT_ACTION_ORDER
    }

    # Stateless defaults are fine to keep
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
  }

  tags = { Name = "nfw-policy-e2w" }
}

resource "aws_networkfirewall_firewall" "this" {
  name                = "nfw-e2w"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.policy.arn
  vpc_id              = aws_vpc.inspect.id

  subnet_mapping { subnet_id = aws_subnet.fw_az[var.azs[0]].id }
  subnet_mapping { subnet_id = aws_subnet.fw_az[var.azs[1]].id }

  tags = { Name = "nfw-e2w" }
}

resource "aws_cloudwatch_log_group" "nfw_flow" { name = "/aws/nfw/e2w/flow" }
resource "aws_cloudwatch_log_group" "nfw_alert" { name = "/aws/nfw/e2w/alert" }

resource "aws_networkfirewall_logging_configuration" "logs" {
  firewall_arn = aws_networkfirewall_firewall.this.arn
  logging_configuration {
    log_destination_config {
      log_type             = "FLOW"
      log_destination_type = "CloudWatchLogs"
      log_destination      = { logGroup = aws_cloudwatch_log_group.nfw_flow.name }
    }
    log_destination_config {
      log_type             = "ALERT"
      log_destination_type = "CloudWatchLogs"
      log_destination      = { logGroup = aws_cloudwatch_log_group.nfw_alert.name }
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_resource_policy" "nfw_delivery" {
  policy_name = "AWSNetworkFirewallLogDelivery"
  policy_document = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "network-firewall.amazonaws.com" },
      Action = [
        "logs:PutLogEvents",
        "logs:CreateLogStream",
        "logs:DescribeLogStreams"
      ],
      Resource = "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/nfw/e2w/*:*"
    }]
  })
}

data "aws_caller_identity" "me" {}

