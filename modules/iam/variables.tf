variable "eks_cluster_role_name" {
  description = "IAM role for EKS cluster"
  type        = string 
}


variable "eks_node_role_name" {
  description = "IAM role for EKS node group"
  type        = string 
} 

variable "env" {
  description = "Environment name"
  type        = string 
}