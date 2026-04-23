
module "networking" {
    source = "./modules/vpc"
    project_name = var.project_name
    region = var.region
    vpc_cidr = var.vpc_cidr
    results_bucket_arn = module.storage.results_bucket_arn
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
    topicarn = module.sns.topicarn
    s3_lambda = var.s3_lambda
    sentinel_lambda = var.sentinel_lambda
    topicarn3 = module.sns.topicarn3
    results_bucket_name = module.storage.results_bucket_name
    reports_bucket_name = module.storage.reports_bucket_name
    results_bucket_arn = module.storage.results_bucket_arn
    reports_bucket_arn = module.storage.reports_bucket_arn
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
    s3_lambda = var.s3_lambda
    sentinel_lambda = var.sentinel_lambda
}

module "logs" {
    source = "./modules/logs"
    project_name = var.project_name
    region = var.region
    results_bucket_arn = module.storage.results_bucket_arn
    results_bucket_name = module.storage.results_bucket_name
    depends_on = [ module.storage ]
}

module "api" {
    source = "./modules/api"
    project_name = var.project_name
    lambda_invoke_arn = module.compute.sentinel_lambda_invoke_arn
    lambda_name = module.compute.sentinel_lambda_name
}