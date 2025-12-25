resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

resource "aws_iam_role" "github_actions_ecr_role" {
  name = "github-actions-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:sai411/Genea_DevSecOps_assignment:*"

          }
        }
      }
    ]
  })
}


resource "aws_iam_policy" "github_ecr_push_policy" {
  name = "github-actions-ecr-push-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "arn:aws:ecr:*:*:repository/genea-usermanagement"
      }
    ]
  })
}

resource "aws_iam_policy" "github_ecs_deploy_policy" {
  name = "github-actions-ecs-deploy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ]
        Resource = [
            "arn:aws:ecs:us-east-1:211395678080:service/genea-cluster/genea-service",
            "arn:aws:ecs:us-east-1:211395678080:task-definition/genea-app:*",
            "arn:aws:ecs:us-east-1:211395678080:cluster/genea-cluster"
     ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_ecr_push_attach" {
  role       = aws_iam_role.github_actions_ecr_role.name
  policy_arn = aws_iam_policy.github_ecr_push_policy.arn
}

resource "aws_iam_role_policy_attachment" "github_ecs_deploy_attach" {
  role       = aws_iam_role.github_actions_ecr_role.name
  policy_arn = aws_iam_policy.github_ecs_deploy_policy.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_ecr_role.arn
}