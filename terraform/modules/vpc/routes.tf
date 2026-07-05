### Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main_vpc.id
  tags = merge({
    Name = "${var.vpc_name}-public-route-table"
  }, var.tags)
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

### Private  route table (single NAT gateway support only for now)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main_vpc.id
  tags = merge({
    Name = "${var.vpc_name}-private-route-table"
  }, var.tags)
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}