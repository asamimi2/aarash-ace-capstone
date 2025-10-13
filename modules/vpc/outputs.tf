output "id"               { value = aws_vpc.this.id }
output "private_subnet_ids" { value = [for s in aws_subnet.private : s.id] }
output "public_subnet_ids"  { value = [for s in aws_subnet.public  : s.id] }
# For TGW attachment we’ll use private subnets:
output "tgw_subnet_ids"     { value = [for s in aws_subnet.private : s.id] }

output "private_route_table_id" {
  value = aws_route_table.private.id
}

# Public route table (for IGW / public subnets)
output "public_route_table_id" {
  description = "The route table ID for the public subnets (if public subnets exist)"
  value       = try(aws_route_table.public.id, null)
}
