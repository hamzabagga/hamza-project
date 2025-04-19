locals {
  env = terraform.workspace
  public_sg_rules_ingress = {for id,rule in csvdecode(file("./sg_rules.csv")): id => rule
   if rule["sg_name"] == "public_sg" && rule["rule_type"] == "ingress"}
  private_sg_rules_ingress = {for id,rule in csvdecode(file("./sg_rules.csv")): id => rule
   if rule["sg_name"] == "private_sg" && rule["rule_type"] == "ingress"}
}

module "network" {
  source = "./modules/network"
  vpc_name = var.vpc_name
  cidr_block = var.cidr_block
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
  igw_name = var.igw_name
  eip_name = var.eip_name
  nat_gateway_name = var.nat_gateway_name
  env = local.env
  public_sg_rules_ingress = local.public_sg_rules_ingress
  private_sg_rules_ingress = local.private_sg_rules_ingress
}