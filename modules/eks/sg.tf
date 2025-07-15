resource "aws_security_group" "eks_node_sg" {
  name        = "eks-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = {
    Name = "eks-node-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "all_internal_tcp" {
  security_group_id = aws_security_group.eks_node_sg.id
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr_block
  description       = "Allow all TCP within VPC"
}

resource "aws_vpc_security_group_ingress_rule" "dns_udp" {
  security_group_id = aws_security_group.eks_node_sg.id
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  cidr_ipv4         = var.vpc_cidr_block
  description       = "DNS UDP"
}

resource "aws_vpc_security_group_ingress_rule" "kubelet_api" {
  security_group_id = aws_security_group.eks_node_sg.id
  from_port         = 10250
  to_port           = 10250
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0" #Ideally should be narrowed based on AWS IP published list
  description       = "Allow EKS control plane to reach kubelet"
}

//ALB SG
resource "aws_vpc_security_group_ingress_rule" "from_alb_80" {
  security_group_id            = aws_security_group.eks_node_sg.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.alb_security_group_id
  description                  = "Allow HTTP from ALB"
}

resource "aws_vpc_security_group_ingress_rule" "from_alb_443" {
  security_group_id            = aws_security_group.eks_node_sg.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.alb_security_group_id
  description                  = "Allow HTTPS from ALB"
}

# Egress rule
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.eks_node_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic"
}

resource "aws_vpc_security_group_ingress_rule" "eks_control_plane_443" {
  security_group_id = aws_security_group.eks_node_sg.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0" # Ideally use AWS IP ranges for EKS control plane
  description       = "Allow EKS control plane access to nodes on port 443"
}