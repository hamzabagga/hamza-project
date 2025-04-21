variable "vpc_name" {
  type = string
  validation {
    condition     = length(var.vpc_name) > 3
    error_message = "vpc_name length must be more then 3 caracteres"
  }
}
variable "cidr_block" {
  type = string
}

variable "public_subnets" {
  type = list(object({
    name              = string # Subnet name tag
    cidr_block        = string # e.g. "10.0.1.0/24"
    availability_zone = string # e.g. "us-east-1a"
  }))


}
variable "private_subnets" {
  type = list(object({
    name              = string # e.g. "private-subnet-1"
    cidr_block        = string # e.g. "10.0.3.0/24"
    availability_zone = string # e.g. "us-east-1a"
  }))
}
variable "igw_name" {
    type = string
  
}
variable "eip_name" {
    type = string
}

variable "nat_gateway_name" {
  type = string
}

variable "cluster_name" {
  type = string
  
  
}
 