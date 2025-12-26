# tfsec:ignore:aws-ecs-enable-container-insight
// Already enabled container insights with enhanced below
resource "aws_ecs_cluster" "genea" {
  name = var.ecs_cluster_name
  setting {
    name  = "containerInsights"
    value = "enhanced"
  }
}

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group" "ecs_service_sg" {
  name        = "genea-ecs-service-sg"
  description = "Security group for ECS service"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "ALB to ECS inside VPC"
  }
  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "ECS to RDS inside VPC"
  }

egress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "ECS to AWS APIs via NAT"
}
tags = {
  "Name" = "genea-ecs-service-sg"
}
}

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group" "lt_sg" {
  name        = "genea-ecs-ec2-sg"
  description = "Security group for ECS EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service_sg.id]
    description     = "Allow all traffic from ECS service"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "EC2 to AWS services"
  }
}

data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}


resource "aws_launch_template" "lt" {
  name                   = "genea-ecs-lt"
  image_id               = data.aws_ssm_parameter.ecs_ami.value
  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.lt_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_ec2_profile.name
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  user_data = base64encode(<<EOF
#!/bin/bash
echo ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config
EOF
  )
}

resource "aws_autoscaling_group" "dev_asg" {
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = var.private_subnet_id

  launch_template {
    id      = aws_launch_template.lt.id
    version = aws_launch_template.lt.latest_version
  }
}

resource "aws_ecs_capacity_provider" "ec2_cp" {
  name = "${var.ecs_cluster_name}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.dev_asg.arn

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster_cp" {
  cluster_name       = aws_ecs_cluster.genea.name
  capacity_providers = [aws_ecs_capacity_provider.ec2_cp.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2_cp.name
    weight            = 1
    base              = 1
  }
}
