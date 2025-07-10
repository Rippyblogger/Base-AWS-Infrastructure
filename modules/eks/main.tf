//Obtain account_id
data "aws_caller_identity" "current" {}


#Create EKS Cluster
resource "aws_eks_cluster" "main" {
  name = var.cluster_name

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.private_subnets
    endpoint_private_access = false
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

resource "aws_eks_access_entry" "admin_access" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.eks_admin_role.arn
  type          = "STANDARD"

  depends_on = [aws_eks_cluster.main]
}

//Create Node Group
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnets
  version         = var.cluster_version
  instance_types  = var.instance_types

  capacity_type = var.capacity_type

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }


  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_group_ssm_core,
  ]
}


// Create certificate for https listener (come back to this)
