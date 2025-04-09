resource "aws_vpc" "main2" {
  cidr_block = var.cidr_block
  tags = {
    Name = var.vpc_name
  }
}

# 2. Create Public Subnets (2x)
resource "aws_subnet" "public" {
  for_each = { for subnet in var.public_subnets : subnet.name => subnet }

  vpc_id                  = aws_vpc.main2.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true  # Hardcoded for public subnets

  tags = {
    Name = each.value.name
  }
}
# resource "aws_subnet" "public" {
#   count                   = 2
#   vpc_id                  = aws_vpc.main2.id
#   cidr_block              = "10.0.${count.index + 1}.0/24"  # 10.0.1.0/24, 10.0.2.0/24
#   availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
#   map_public_ip_on_launch = true  # Required for public subnets

#   tags = {
#     Name = "public-subnet-${count.index + 1}"
#   }
# } 

# 3. Create Private Subnets (2x)
resource "aws_subnet" "private" {
  for_each = { for subnet in var.private_subnets : subnet.name => subnet }

  vpc_id                  = aws_vpc.main2.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false  # Explicitly private

  tags = {
    Name = each.value.name
  }
}
# resource "aws_subnet" "private" {
#   count             = 2
#   vpc_id            = aws_vpc.main2.id
#   cidr_block        = "10.0.${count.index + 3}.0/24"  # 10.0.3.0/24, 10.0.4.0/24
#   availability_zone = element(["us-east-1a", "us-east-1b"], count.index)

#   tags = {
#     Name = "private-subnet-${count.index + 1}"
#   }
# }

# 4. Internet Gateway (for public subnets)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main2.id
  tags = {
    Name = "main-igw"
  }
}

# 5. Elastic IP (for NAT Gateway)
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "nat-gateway-eip"
  }
}

# 6. NAT Gateway (placed in 1st public subnet)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id  # Attach to public subnet
  depends_on    = [aws_internet_gateway.igw]  # Explicit dependency

  tags = {
    Name = "main-nat"
  }
}

# 7. Public Route Table (routes to Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# 8. Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 9. Private Route Table (routes to NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main2.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt"
  }
}

# 10. Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
