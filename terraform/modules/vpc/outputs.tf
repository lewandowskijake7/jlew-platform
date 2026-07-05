output "public_subnet_ids" {
  value = { for k, subnet in aws_subnet.public : k => subnet.id }
}

output "private_subnet_ids" {
  value = { for k, subnet in aws_subnet.private : k => subnet.id }
}

output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.main_vpc.cidr_block
}

output "igw_id" {
  value = aws_internet_gateway.main_igw.id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.nat_gateway.id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}