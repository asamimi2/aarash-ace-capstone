variable "dev_account_id" { type = string }
variable "prod_account_id" { type = string }

resource "aws_ram_resource_share" "tgw" {
  name                      = "tgw-share"
  allow_external_principals = false
}

resource "aws_ram_principal_association" "dev" {
  resource_share_arn = aws_ram_resource_share.tgw.arn
  principal          = var.dev_account_id
}

resource "aws_ram_principal_association" "prod" {
  resource_share_arn = aws_ram_resource_share.tgw.arn
  principal          = var.prod_account_id
}

resource "aws_ram_resource_association" "tgw" {
  resource_share_arn = aws_ram_resource_share.tgw.arn
  resource_arn       = module.tgw.tgw_arn
}
