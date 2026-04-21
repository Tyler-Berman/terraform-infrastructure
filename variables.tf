variable "project_name" {
    type = string
    default = "sentinel-v2"
}

variable "region" {
    type = string
    default = "us-east-1"
}

variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
}

variable "ec2_lambda" {
    type = string
    default = "EC2_Lambda_Sentinel"
}

variable "updates_email" {
    type = string
    default = "example@example.com"
}

variable "s3_lambda" {
    type = string
    default = "S3_Lambda_Sentinel"
}