variable "region" {
    type = string
}

variable "project_name" {
    type = string
}

variable "vpc_id" {
    type = string 
}

variable "ingress_ports" {
    type = list(string)
    description = "List of open ports for Sentinel"
}