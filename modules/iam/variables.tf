variable "target_vpc_id" {
    type = string
}

variable "ingress_ports" {
    type = list(number)
    description = "List of ports to open for Sentinel"
}