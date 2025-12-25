variable "ecs_cluster_name" {
  default = "genea-cluster"
}

variable "ecs_svc_name" {
  default = "genea-service"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_id" {
  type = list(string)
}

variable "pub_subnet_ids" {
  type = list(string)
}

variable "dbhost" {
  type = string
}

variable "dbuser" {
  type = string
}

variable "db_password" {
  type = string
}

variable "execution_role_arn" {
  type    = string
  default = "arn:aws:iam::975050104106:role/ecsTaskExecutionRole"
}

variable "container_image" {
  type    = string
  default = "211395678080.dkr.ecr.us-east-1.amazonaws.com/genea-usermanagement:latest"
}

variable "vpc_cidr" {
  type = string
}

variable "ecr_repository_arn" {
  type = string
  default = "arn:aws:ecr:us-east-1:211395678080:repository/genea-usermanagement"
}