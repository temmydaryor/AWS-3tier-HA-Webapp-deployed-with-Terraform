module "vpc" {
  source = "./modules/vpc"

  project_name          = var.project_name
  vpc_cidr              = var.vpc_cidr
  azs                   = var.azs
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  single_nat_gateway    = var.single_nat_gateway
}

module "security_groups" {
  source = "./modules/security_groups"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  admin_cidr   = var.admin_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
}

module "asg" {
  source = "./modules/asg"

  project_name        = var.project_name
  private_subnet_ids  = module.vpc.private_subnet_ids
  app_sg_id           = module.security_groups.app_sg_id
  target_group_arn    = module.alb.target_group_arn
  instance_type       = var.instance_type
  key_name            = var.key_name
}

module "rds" {
  source = "./modules/rds"

  project_name        = var.project_name
  private_subnet_ids  = module.vpc.private_subnet_ids
  db_sg_id            = module.security_groups.db_sg_id
  db_username         = var.db_username
  db_password         = var.db_password
}

module "cdn" {
  source = "./modules/cdn"

  project_name = var.project_name
  bucket_name  = var.asset_bucket_name
}
