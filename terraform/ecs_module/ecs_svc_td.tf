resource "aws_ecs_task_definition" "service" {
  family                   = "genea-app"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "genea-app"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        { 
          name = "DB_NAME", value = "devdb"
        },
        { 
          name = "DB_HOST", value = var.dbhost 
        },
        { 
          name = "DB_PORT", value = "3306" 
        },
        { 
        name = "DB_USER", value = var.dbuser
        }
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.db_password}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "genea-ecs-logs"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }
    },
    {
      name      = "aws-otel-collector"
      image     = "public.ecr.aws/aws-observability/aws-otel-collector:v0.46.0"
      essential = true

      command = [
        "--config=/etc/ecs/ecs-cloudwatch-xray.yaml"
      ]

      portMappings = [
        {
          containerPort = 2000
          hostPort      = 2000
          protocol      = "udp"
        },
        {
          containerPort = 4317
          hostPort      = 4317
          protocol      = "tcp"
        },
        {
          containerPort = 8125
          hostPort      = 8125
          protocol      = "udp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/ecs-aws-otel-sidecar-collector"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
          mode                  = "non-blocking"
          max-buffer-size       = "25m"
        }
      }
    }
  ])
}


resource "aws_ecs_service" "service" {
  name            = var.ecs_svc_name
  cluster         = aws_ecs_cluster.genea.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = 1
  force_new_deployment = true
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2_cp.name
    weight = 1
  }
  network_configuration {
    subnets         = var.private_subnet_id
    security_groups = [aws_security_group.ecs_service_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.genea_tg.arn
    container_name   = "genea-app"
    container_port   = 8000
  }

  health_check_grace_period_seconds = 30
}

output "aws_ecs_security_group_id" {
  value = aws_security_group.ecs_service_sg.id
  
}