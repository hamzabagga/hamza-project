variable "vpc_name" {
  type = string
  validation {
    condition = length(var.vpc_name) > 3
    error_message = "vpc_name length must be more then 3 caracteres"
  }
}
variable "cidr_block" {
    type = string
}

variable "public_subnets" {
  type = list(object({
    name              = string  # Subnet name tag
    cidr_block        = string  # e.g. "10.0.1.0/24"
    availability_zone = string  # e.g. "us-east-1a"
  }))

  validation {
    condition = alltrue([
      for s in var.public_subnets :
      can(cidrhost(s.cidr_block, 0)) && length(s.name) > 3
    ])
    error_message = "All subnets must have valid CIDR blocks and names >3 characters"
  }
}
variable "private_subnets" {
  type = list(object({
    name              = string  # e.g. "private-subnet-1"
    cidr_block        = string  # e.g. "10.0.3.0/24"
    availability_zone = string  # e.g. "us-east-1a"
  }))

  validation {
    condition = alltrue([
      for s in var.private_subnets :
      can(cidrhost(s.cidr_block, 0)) && length(s.name) > 3
    ])
    error_message = "All subnets must have valid CIDR blocks and names >3 characters"
  }
}