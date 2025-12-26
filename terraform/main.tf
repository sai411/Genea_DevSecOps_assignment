module "vpc" {
  source = "./vpc_module"
}

module "ecs" {
  source            = "./ecs_module"
  vpc_id            = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_id
  pub_subnet_ids    = module.vpc.pub_subnet_id
  dbhost            = module.rds.dbhost
  dbuser            = module.rds.dbuser
  db_password       = module.rds.db_secret_arn
  vpc_cidr          = module.vpc.vpc_cidr_block
}


module "rds" {
  source            = "./rds_module"
  vpc_id            = module.vpc.vpc_id
  pvt_subnet_ids    = module.vpc.private_subnet_id
  ecs_service_sg_id = module.ecs.aws_ecs_security_group_id
}

output "alb_hostname" {
  value = module.ecs.alb_hostname
}

output "github_actions_role_arn" {
  value = module.ecs.github_actions_role_arn

}
