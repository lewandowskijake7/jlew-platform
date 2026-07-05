resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = merge({
    Name = "${var.vpc_name}-nat-eip"
  }, var.tags)
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[local.nat_public_subnet_key].id

  depends_on = [aws_internet_gateway.main_igw, 
                aws_route.public_internet]
  tags = merge({
    Name = "${var.vpc_name}-nat-gateway"
  }, var.tags)
}