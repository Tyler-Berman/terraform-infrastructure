
module "networking" {
    source = "./modules/vpc"
    project_name = var.project_name
    region = var.region
    vpc_cidr = var.vpc_cidr
}

module "security" {
    source = "./modules/security"
    project_name = var.project_name
    region = var.region
    ingress_ports = [80,443,22,8080]
    vpc_id = module.networking.vpc_id
}

module "compute" {
    source = "./modules/compute"
    project_name = var.project_name
    region = var.region
    subnet_id = module.networking.public_subnet_id
    vpc_sg_id = [module.security.sg_id]
    iam_instance_profile = module.storage.instance_profile_name
    ec2_lambda = var.ec2_lambda
    topicarn2 = module.sns.topicarn2
}

module "storage" {
    source = "./modules/storage"
    project_name = var.project_name
}
module "sns" {
    source = "./modules/sns"
    ec2_lambda = var.ec2_lambda
    region = var.region
    updates_email = var.updates_email
}