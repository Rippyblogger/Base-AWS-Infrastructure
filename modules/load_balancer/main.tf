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
  to_port           = 65535

tags = {
    Name = "Allow Internal traffic"
  }
  lifecycle {
    create_before_destroy = true
  }
}

//Create S3 bucket to hold LB access logs

resource "aws_s3_bucket" "lb_logs" {
  bucket = "LB Accesslogs bucket"

  tags = {
    Name        = "LB_Access_logs"
  }
}

// Create Load balancer

resource "aws_lb" "internal" {
  name               = "internal-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_internal_traffic.id]
  subnets            = var.private_subnets

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "lb-access-"
    enabled = true
  }

  tags = {
    Name = "internal-lb"
  }
}