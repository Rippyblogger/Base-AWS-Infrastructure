#Create security groups
resource "aws_security_group" "allow_internal_traffic" {
  name        = "Allow Internal traffic"
  description = "Allow ports"
  vpc_id      = var.vpc_id

  tags = {
    Name = "Allow Internal traffic"
  }
}

#Create ingress rule
resource "aws_vpc_security_group_ingress_rule" "allow_internal_traffic" {

  security_group_id = aws_security_group.allow_internal_traffic.id
  cidr_ipv4         = var.vpc_cidr_block
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
  name               = "Shared-Internal-lb"
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

// Create listeners

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Default (HTTP)"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "443"
  protocol          = "HTTPS"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Default backend (HTTPS)"
      status_code  = "404"
    }
  }
}