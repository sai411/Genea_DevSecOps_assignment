resource "aws_vpc" "dev-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dev-vpc"
  }
}

#tfsec:ignore:aws-ec2-no-public-ip-subnet
resource "aws_subnet" "Dev-public" {
  count                   = length(var.public_subnets_cidr)
  vpc_id                  = aws_vpc.dev-vpc.id
  cidr_block              = var.public_subnets_cidr[count.index]
  availability_zone       = var.az[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "dev-public-${count.index}"
  }
}

resource "aws_subnet" "Dev-private" {
  count                   = length(var.private_subnets_cidr)
  vpc_id                  = aws_vpc.dev-vpc.id
  cidr_block              = var.private_subnets_cidr[count.index]
  availability_zone       = var.az[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "dev-private-${count.index}"
  }
}

resource "aws_internet_gateway" "dev-igw" {
  vpc_id = aws_vpc.dev-vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_eip" "eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "my-nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.Dev-public[0].id

  tags = {
    Name = "dev-nat"
  }

  depends_on = [aws_internet_gateway.dev-igw]
}

resource "aws_route_table" "public_routes" {
  vpc_id = aws_vpc.dev-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev-igw.id
  }

  tags = {
    Name = "public-route"
  }
}

resource "aws_route_table_association" "pub-association" {
  count          = length(aws_subnet.Dev-public)
  subnet_id      = aws_subnet.Dev-public[count.index].id
  route_table_id = aws_route_table.public_routes.id
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.dev-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my-nat.id
  }

  tags = {
    Name = "private-route"
  }
}

resource "aws_route_table_association" "pvt-association" {
  count          = length(aws_subnet.Dev-private)
  subnet_id      = aws_subnet.Dev-private[count.index].id
  route_table_id = aws_route_table.private_route.id
}



# Enabling vpc_flowlogs

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "cloudwatch_logs_key" {
  description             = "KMS key for CloudWatch Logs and VPC Flow Logs"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRootAccount"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsService"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      },
    
      {
        Sid    = "AllowVPCFlowLogsRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_vpc_flow_logs.vpc_flow_logs_role.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs/dev-vpc"
  retention_in_days = 30
  kms_key_id = aws_kms_key.cloudwatch_logs_key.arn
}

resource "aws_log" "name" {
  
}

resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "vpc_flow_logs_policy" {
  name = "vpc-flow-logs-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowWriteFlowLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:log-stream:*"
      },
      {
        Sid    = "AllowDescribe"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = aws_cloudwatch_log_group.vpc_flow_logs.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_flow_logs_attach" {
  role       = aws_iam_role.vpc_flow_logs_role.name
  policy_arn = aws_iam_policy.vpc_flow_logs_policy.arn
}

resource "aws_flow_log" "vpc_flow_logs" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.dev-vpc.id
  iam_role_arn         = aws_iam_role.vpc_flow_logs_role.arn
}

