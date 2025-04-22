locals {
  env = terraform.workspace

  public_sg_rules_ingress = {
    for id, rule in csvdecode(file("./sg_rules.csv")) :
    id => {
      protocol    = rule["protocol"]
      from_port   = tonumber(split("-", rule["port_range"])[0])
      to_port     = length(split("-", rule["port_range"])) > 1 ? tonumber(split("-", rule["port_range"])[1]) : tonumber(split("-", rule["port_range"])[0])
      cidr_blocks = rule["dst_cidr"] 
      rule_type   = rule["rule_type"]
      dst_sg      = rule["dst_sg"] 
    }
    if rule["sg_name"] == "public_sg" && rule["rule_type"] == "ingress"
  }

  private_sg_rules_ingress = {
    for id, rule in csvdecode(file("./sg_rules.csv")) :
    id => {
      protocol    = rule["protocol"]
      from_port   = tonumber(split("-", rule["port_range"])[0])
      to_port     = length(split("-", rule["port_range"])) > 1 ? tonumber(split("-", rule["port_range"])[1]) : tonumber(split("-", rule["port_range"])[0])
      cidr_blocks = rule["dst_cidr"] 
      rule_type   = rule["rule_type"]
      dst_sg      = rule["dst_sg"] 
    }
    if rule["sg_name"] == "private_sg" && rule["rule_type"] == "ingress"
  }
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

module "iam" {
  source = "./modules/iam"
  env = local.env
  eks_cluster_role_name = "med-eks-cluster-role"
  eks_node_role_name = "med-eks-node-role"
  depends_on = [ module.network]
}

data "aws_iam_group" "admins"{
  group_name = "admins"
}

locals {
  devops_users =data.aws_iam_group.admins.users[*].arn
  eks_access_entries_devops = flatten([
    for user_arn in local.devops_users : {
      cluster_name = var.cluster_name
      principal_arn = user_arn
    }
  ])
}


module "kubernetes" {
  source = "./modules/eks"
  env = local.env
  cluster_name = var.cluster_name
  eks_cluster_role_arn = module.iam.iam_cluster_role_arn
  eks_access_entries_devops = local.eks_access_entries_devops
  eks_node_role_arn = module.iam.iam_node_role_arn
  private_subnet_ids = module.network.private_subnet_ids
  depends_on = [ module.iam, module.network]
}

