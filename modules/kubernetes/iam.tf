resource "aws_iam_role" "irsa_role" {
  name = "my-go-api-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = var.oidc_arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:default:${var.service_account_name}"
        }
      }
    }]
  })
}

# EC2 read permissions for /vpcs and /ec2s endpoints
resource "aws_iam_role_policy_attachment" "ec2_read_permissions" {
  role       = aws_iam_role.irsa_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# Service Quotas read permissions for /quotas endpoint
resource "aws_iam_role_policy_attachment" "quota_read_permissions" {
  role       = aws_iam_role.irsa_role.name
  policy_arn = "arn:aws:iam::aws:policy/ServiceQuotasReadOnlyAccess"
}

# Custom policy for EKS describe permissions and Service Quotas write
resource "aws_iam_policy" "app_custom_permissions" {
  name        = "app-custom-permissions"
  description = "Custom permissions for the API app"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "servicequotas:RequestServiceQuotaIncrease",
          "servicequotas:GetRequestedServiceQuotaChange",
          "servicequotas:ListRequestedServiceQuotaChangeHistory",
          "servicequotas:GetServiceQuota",
          "servicequotas:ListServiceQuotas",
          "servicequotas:GetAWSDefaultServiceQuota"
        ]
        Resource = "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "iam:CreateServiceLinkedRole",
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "iam:AWSServiceName" : "servicequotas.amazonaws.com"
          }
        }
      }

    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_custom_permissions" {
  role       = aws_iam_role.irsa_role.name
  policy_arn = aws_iam_policy.app_custom_permissions.arn
}
