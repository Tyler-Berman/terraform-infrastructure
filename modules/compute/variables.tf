variable "vpc_sg_id" {
    type = list(string)
}

variable "project_name" {
    type = string
}

variable "region" {
    type = string
}

variable "subnet_id" {
    type = string
}

variable "iam_instance_profile" {
    type = string
}

variable "ec2_lambda" {
    type = string
}

variable "s3_lambda" {
  type = string
}

variable "sentinel_lambda" {
  type = string
}
variable "topicarn2" {
    type = string
}

variable "topicarn" {
  type = string
}

variable "topicarn3" {
    type = string
}

variable "results_bucket_arn" {
    type = string
}

variable "reports_bucket_arn" {
    type = string
}

variable "results_bucket_name" {
    type = string
}

variable "reports_bucket_name" {
    type = string
}