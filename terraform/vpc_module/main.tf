resource "aws_vpc" "dev-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dev-vpc"
  }
}

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

resource "aws_iam_policy" "vpc_flow_logs_policy" {
  name = "vpc-flow-logs-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}
