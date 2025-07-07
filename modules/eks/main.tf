//Obtain EKS optimized AMI
data "aws_ami" "eks_worker" {
  most_recent = true
  owners      = ["602401143452"] # Official EKS AMI owner ID

  filter {
    name   = "name"
    values = ["amazon-eks-node-*-v*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


//Obtain account_id
data "aws_caller_identity" "current" {}

#Create EKS Cluster
resource "aws_eks_cluster" "main" {
  name = var.cluster_name

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids = var.private_subnets
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

//Create Node Groups
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnets

  capacity_type  = var.capacity_type
  instance_types = var.instance_types

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.eks_node_lt.id
    version = "$Latest"
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_eks_access_entry" "admin_access" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AdminRole"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_policy" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_eks_access_entry.admin_access.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

// Create Launch template for Node Group
resource "aws_launch_template" "eks_node_lt" {
  name_prefix   = "eks-node-lt-"
  # image_id      = var.ami_id
  image_id      = data.aws_ami.eks_worker.id        
  instance_type = var.instance_type 

  vpc_security_group_ids = [
    aws_security_group.eks_node_sg.id
  ]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-node"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
