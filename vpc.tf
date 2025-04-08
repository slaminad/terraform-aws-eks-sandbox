data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  available_azs = data.aws_availability_zones.available.names
  networks = {
    sandbox = {
      cidr = var.cidr_block
      public_subnets  = var.public_subnets
      private_subnets = var.private_subnets
      selected_azs = slice(local.available_azs, 0, var.number_azs)
    }
  }
  region = local.install_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.5"

  name = var.nuon_id
  cidr = local.networks["sandbox"]["cidr"]

  azs             = local.networks["sandbox"]["selected_azs"]
  private_subnets = local.networks["sandbox"]["private_subnets"]
  public_subnets  = local.networks["sandbox"]["public_subnets"]

  enable_nat_gateway           = true
  #single_nat_gateway           = true
  enable_dns_hostnames         = true
  create_database_subnet_group = true
  #create_elasticache_subnet_group = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
    "visibility"                                  = "public"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
    "visibility"                                  = "private"
  }

  tags = local.tags
}
