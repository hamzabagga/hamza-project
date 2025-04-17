output "vpc_id" {
    description = "The ID of the VPC"
    value       = aws_vpc.main2.id
  
}

output "public_sg_rules_ingress" {
    value = local.public_sg_rules_ingress
  
}