variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "tgw_id" {
  type = string
}

variable "appliance_mode" {
  type    = bool
  default = true
}
