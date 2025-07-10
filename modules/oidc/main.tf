//Obtain account_id
data "aws_caller_identity" "current" {}

//Create ODIC provider config
resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list = ["sts.amazonaws.com"]
  url            = "https://token.actions.githubusercontent.com"
}

// OIDC Iam Role definition
resource "aws_iam_role" "oidc_role" {
  name = "oidc_role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub" : "repo:${var.github_username}/${var.github_repository}:ref:refs/heads/${var.github_branch}"
          }
        }
      }
    ]
    }
  )
}

//Attach role policy
resource "aws_iam_role_policy" "oidc_deploy_policy" {
  name = "oidc-deploy-policy"
  role = aws_iam_role.oidc_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "EKSManagement",
        Effect = "Allow",
        Action = [
          "eks:*"
        ],
        Resource = "*"
      },
      {
        Sid    = "EC2Networking",
        Effect = "Allow",
        Action = [
          "ec2:Describe*",
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:CreateInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:CreateNatGateway",
          "ec2:DeleteNatGateway",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:CreateRoute",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:ModifySubnetAttribute",
          "ec2:CreateTags"
        ],
        Resource = "*"
      },
      {
        Sid    = "ELBAccess",
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:*"
        ],
        Resource = "*"
      },
      {
        Sid    = "IAMPassRoleForEKS",
        Effect = "Allow",
        Action = [
          "iam:PassRole",
          "iam:GetRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy"
        ],
        Resource = "*"
      },
      {
        Sid    = "S3Logging",
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:CreateBucket"
        ],
        Resource = "*"
      },
      {
        Sid    = "STSCallerIdentity",
        Effect = "Allow",
        Action = [
          "sts:GetCallerIdentity"
        ],
        Resource = "*"
      }
    ]
  })
}
