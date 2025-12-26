variable "pvt_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "ecs_service_sg_id" {

}

variable "secrets_arn" {

  type        = string
  default     = "arn:aws:secretsmanager:us-east-1:211395678080:secret:RDS-Secrets-EwHRyx"
}