
module "vpc" {
  source = "./modules/vpc"
}

module "security" {
  source = "./modules/security"
  vpc_id = module.vpc.vpc_id
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = "TEST-BUCKET" 
}

module "iam" {
  source     = "./modules/iam"
  bucket_arn = module.s3.bucket_arn
}

module "ec2" {
  source            = "./modules/ec2"
  instance_type     = var.instance_type
  instance_count    = var.instance_count
  subnet_id         = module.vpc.public_subnet
  security_group_id = module.security.security_group
  instance_profile  = module.iam.instance_profile
}
