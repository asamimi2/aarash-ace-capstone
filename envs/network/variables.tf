variable "asn" {
  type        = number
  default     = 64512
  description = "TGW Amazon-side ASN"
}

variable "region" { type = string }
variable "azs" { type = list(string) } # ["us-east-1a","us-east-1b"]

variable "inspection_vpc_cidr" { type = string } # e.g., "10.30.0.0/24"

# CIDRs for routing + NFW rules
variable "dev_cidr" { type = string }  # "10.10.0.0/16"
variable "prod_cidr" { type = string } # "10.20.0.0/16"
variable "home_cidr" { type = string } # your home/on-prem LAN, e.g., "192.168.1.0/24"