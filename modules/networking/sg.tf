resource "aws_security_group" "allow_ports" {
  name        = "allow_ports"
  description = "Allow neccsary ports"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "allow_ports"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ports_ipv4" {
  for_each = [80, 443, 10250]

  security_group_id = aws_security_group.allow_ports.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = each.value
  ip_protocol       = "tcp"
  to_port           = each.value

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "allow_internal_traffic" {
  name        = "Allow Internal traffic"
  description = "Allow ports"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "Allow Internal traffic"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_internal_traffic" {

  security_group_id = aws_security_group.allow_internal_traffic.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 0
  ip_protocol       = "-1"
  to_port           = 0

  lifecycle {
    create_before_destroy = true
  }
}
