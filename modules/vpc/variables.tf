variable "name" {
  type = string
}

variable "cidr" {
  type = string
}

variable "create_public_subnets" {
  type    = bool
  default = false
}

variable "private_azs" {
  type    = number
  default = 2
}
