resource "aws_vpc" "main2" {
  cidr_block = var.cidr_block
  tags = {
    Name = "${var.vpc_name}-${var.env}"
  }
}

# 2. Create Public Subnets (2x)
resource "aws_subnet" "public" {
  count =  length(var.public_subnets)

  
  vpc_id                  = aws_vpc.main2.id
  cidr_block              = var.public_subnets[count.index].cidr_block
  availability_zone       = var.public_subnets[count.index].availability_zone
  map_public_ip_on_launch = true  # Hardcoded for public subnets

  tags = {
    Name = "${var.public_subnets[count.index].name}-${var.env}"
  }
  depends_on = [ aws_vpc.main2 ]
}


# 3. Create Private Subnets (2x)
resource "aws_subnet" "private" {
  count =  length(var.private_subnets)

  
  vpc_id                  = aws_vpc.main2.id
  cidr_block              = var.private_subnets[count.index].cidr_block
  availability_zone       = var.private_subnets[count.index].availability_zone
  map_public_ip_on_launch = false  # Hardcoded for public subnets

  tags = {
    Name = "${var.private_subnets[count.index].name}-${var.env}"
  }
  depends_on = [ aws_vpc.main2 ]
}



# 4. Internet Gateway (for public subnets)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main2.id
  tags = {
    Name = "${var.igw_name}-${var.env}"
  }
  depends_on = [ aws_vpc.main2 ]
}

# 5. Elastic IP (for NAT Gateway)
resource "aws_eip" "nat_eip" {
  count =  length(var.private_subnets)
  domain = "vpc"
  tags = {
    Name = "${var.eip_name}-${count.index}-${var.env}"
  }
  depends_on = [ aws_internet_gateway.igw ] # Explicit dependency
}

# 6. NAT Gateway (placed in 1st public subnet)
resource "aws_nat_gateway" "nat" {
  count =  length(var.private_subnets)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id # Attach to public subnet
  tags = {
    Name = "${var.nat_gateway_name}-${count.index}-${var.env}"
  }
  depends_on = [ aws_eip.nat_eip, aws_subnet.public] # Explicit dependency
}

# 7. Public Route Table (routes to Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt-${var.env}"
  }
  depends_on = [ aws_internet_gateway.igw , aws_subnet.public] # Explicit dependency
}

# 8. Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count =  length(var.public_subnets)

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = element(aws_route_table.public[*].id, count.index)
  depends_on = [ aws_route_table.public, aws_subnet.public] # Explicit dependency
}

# 9. Private Route Table (routes to NAT Gateway)
resource "aws_route_table" "private" {
  count =  length(var.private_subnets)
  vpc_id = aws_vpc.main2.id
 

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "private-rt-${count.index}-${var.env}"
  }
  depends_on = [ aws_nat_gateway.nat, aws_subnet.private] # Explicit dependency
}

# 10. Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {

  count =  length(var.private_subnets)
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(aws_route_table.private[*].id, count.index)
  depends_on = [ aws_route_table.private, aws_subnet.private] # Explicit dependency
}

resource "aws_security_group" "public_sg" {
  name        = "public-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main2.id  # Ton VPC

  tags = {
    Name = "web-sg"
  }
  depends_on = [ aws_subnet.public ]
}

resource "aws_security_group" "private_sg" {
  name        = "private-sg"
  description = "Allow private access"
  vpc_id      = aws_vpc.main2.id  # Ton VPC

  tags = {
    Name = "web-sg"
  }
  depends_on = [ aws_subnet.private ]
}

resource "aws_security_group_rule" "public_sg_rules" {
  for_each = var.public_sg_rules_ingress

  security_group_id = aws_security_group.public_sg.id
  type              = each.value.rule_type
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = each.value.cidr_blocks != "" ? [each.value.cidr_blocks] : null
  source_security_group_id = each.value.dst_sg != "" ? aws_security_group.private_sg.id : null
  depends_on = [ aws_security_group.public_sg ]
}

resource "aws_security_group_rule" "private_sg_rules" {
  for_each = var.private_sg_rules_ingress

  security_group_id = aws_security_group.private_sg.id
  type              = each.value.rule_type
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = each.value.cidr_blocks != "" ? [each.value.cidr_blocks] : null
  source_security_group_id = each.value.dst_sg != "" ? aws_security_group.public_sg.id : null
  depends_on = [ aws_security_group.private_sg ]
}