//Main VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true


  tags = {
    Name = "main-vpc"
  }
}

//Obtain avaialbility zone data
data "aws_availability_zones" "available" {
  state = "available"
}

//Create public and private subnet resources

resource "aws_subnet" "public_subnets" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[
    index(keys(var.public_subnets), each.key)
  ]
  tags = {
    Name                                        = each.key
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_subnet" "private_subnets" {
  for_each                = var.private_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  map_public_ip_on_launch = false
  availability_zone = data.aws_availability_zones.available.names[
    index(keys(var.private_subnets), each.key)
  ]
  tags = {
    Name                                        = each.key
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

//Create IGW and Attachment
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IGW attachment"
  }
}

// Create elastic IP
resource "aws_eip" "natgw" {
  domain = "vpc"

  tags = {
    Name = "Main-elastic_ip"
  }
}

// Create NAT Gateways
resource "aws_nat_gateway" "nat_gw" {

  allocation_id = aws_eip.natgw.id
  subnet_id     = aws_subnet.public_subnets[local.first_public_subnet_key].id

  tags = {
    Name = "${local.first_public_subnet_key}-NAT-GW"
  }

  depends_on = [aws_internet_gateway.gw]
}

//Create Routes to NAT-GW

resource "aws_route_table" "pvt_routes" {

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "Private subnets routing table"
  }
}

resource "aws_route_table_association" "pvt_subnets" {
  for_each       = var.private_subnets
  subnet_id      = aws_subnet.private_subnets[each.key].id
  route_table_id = aws_route_table.pvt_routes.id
}

//Create Route to IGW

resource "aws_route_table" "pub_routes" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "main_route_table"
  }
}

resource "aws_route_table_association" "pub_subnets" {
  for_each       = var.public_subnets
  subnet_id      = aws_subnet.public_subnets[each.key].id
  route_table_id = aws_route_table.pub_routes.id
}
