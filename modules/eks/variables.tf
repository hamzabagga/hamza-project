variable "env" {
  description = "Environment name"
  type        = string  
}

variable "eks_cluster_role_arn" {
  description = "IAM role ARN for EKS cluster"
  type        = string 
}

variable "eks_node_role_arn" {
  description = "IAM role ARN for EKS node group"
  type        = string  
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}


variable "eks_access_entries_devops" {
  description = "List of access entries for DevOps users"
  type        = list(object({
    cluster_name   = string
    principal_arn  = string
  }))  
}