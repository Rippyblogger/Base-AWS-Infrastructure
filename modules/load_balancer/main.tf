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
  to_port           = 65535
  ip_protocol       = "tcp"
  description       = "Allow internal TCP"

tags = {
    Name = "Allow Internal traffic"
  }
  lifecycle {
    create_before_destroy = true
  }
}

//Create S3 bucket to hold LB access logs

resource "aws_s3_bucket" "lb_logs" {
  bucket = var.lb_logs_bucket_name
  force_destroy = true //Remove later

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

  enable_deletion_protection = false // Remove later

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "lb_access_log"
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

# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.internal.arn
#   port              = "443"
#   protocol          = "HTTPS"

#   default_action {
#     type = "fixed-response"
#     fixed_response {
#       content_type = "text/plain"
#       message_body = "Default backend (HTTPS)"
#       status_code  = "404"
#     }
#   }
# }

// Grant permission to ALB to modify s3 bucket

resource "aws_s3_bucket_policy" "allow_alb_access_logs" {
  bucket = aws_s3_bucket.lb_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSLogDeliveryWrite",
        Effect    = "Allow",
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        },
        Action    = [
          "s3:PutObject"
        ],
        Resource  = "${aws_s3_bucket.lb_logs.arn}/*"
      },
      {
        Sid       = "AWSLogDeliveryAclCheck",
        Effect    = "Allow",
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        },
        Action    = "s3:GetBucketAcl",
        Resource  = aws_s3_bucket.lb_logs.arn
      }
    ]
  })
}
