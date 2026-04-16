
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
