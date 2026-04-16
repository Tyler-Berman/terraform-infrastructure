
module "my_vpc_module" {
    source = "./modules/vpc"
    
}

module "my_sg_module" {
    source = "./modules/iam"
    target_vpc_id = module.my_vpc_module.vpc_id
    ingress_ports = [80,443,22,8080]
}

module "my_ec2_module" {
    source = "./modules/compute"
    vpc_sg_id = [module.my_sg_module.sg_id]
}