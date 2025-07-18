output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}

output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

