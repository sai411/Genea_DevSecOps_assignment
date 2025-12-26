resource "aws_ecs_task_definition" "db_migration_taskdefinition" {
  family                   = "genea-db-migration"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "256"

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "genea-db-migration"
      image     = var.container_DB_image
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
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
          awslogs-group         = "genea-db-migration-ecs-logs"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
        }
      }
    }
  ])
}
