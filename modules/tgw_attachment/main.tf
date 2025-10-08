locals {
  appliance = var.appliance_mode ? "enable" : "disable"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  vpc_id                 = var.vpc_id
  subnet_ids             = var.subnet_ids
  transit_gateway_id     = var.tgw_id
  appliance_mode_support = local.appliance
  tags = { Name = "tgw-attach-${var.vpc_id}" }
}
