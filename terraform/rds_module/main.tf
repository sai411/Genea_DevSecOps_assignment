data "aws_secretsmanager_secret" "rds_secret" {
  arn = "arn:aws:secretsmanager:us-east-1:211395678080:secret:RDS-Secrets-EwHRyx"
}

data "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = data.aws_secretsmanager_secret.rds_secret.id
}

locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.rds_secret_version.secret_string)
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = var.pvt_subnet_ids

  tags = {
    Name = "db-subnet-group"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.ecs_service_sg_id]
    description     = "ECS service to RDS inside VPC"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [var.ecs_service_sg_id]
    description     = "Allow outbound only to ECS service"
}
}

resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}



resource "aws_db_instance" "sql-db" {
  allocated_storage                   = 10
  db_name                             = "devdb"
  identifier                          = "ee-instance-demo"
  engine                              = "mysql"
  engine_version                      = "5.7"
  instance_class                      = "db.t3.micro"
  username                            = local.db_credentials.username
  password                            = local.db_credentials.password
  parameter_group_name                = "default.mysql5.7"
  availability_zone                   = "us-east-1a"
  iam_database_authentication_enabled = true
  skip_final_snapshot                 = true
  storage_encrypted                   = true
  kms_key_id        = aws_kms_key.rds.arn
  backup_retention_period = 7
  deletion_protection = true

  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}
