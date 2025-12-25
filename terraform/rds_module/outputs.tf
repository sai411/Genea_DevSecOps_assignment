output "dbhost" {
  value = aws_db_instance.sql-db.address
}

output "dbuser" {
  value = local.db_credentials.username
}

output "db_secret_arn" {
  value = data.aws_secretsmanager_secret.rds_secret.arn
}

output "rds_security_group_id" {
  value = aws_security_group.db_sg.id
  
}