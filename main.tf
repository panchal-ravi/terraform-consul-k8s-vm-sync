locals {
  deployment_id = lower("${var.owner}-${random_string.suffix.result}")
}

resource "random_string" "suffix" {
  length  = 4
  special = false
}

module "infra" {
  source               = "./modules/infra"
  deployment_id        = local.deployment_id
  owner                = var.owner
  region               = var.region
  vpc_cidr             = var.vpc_cidr
  private_subnets      = var.private_subnets
  public_subnets       = var.public_subnets
  cluster_version      = var.aws_eks_cluster_version
  cluster_service_cidr = var.aws_eks_cluster_service_cidr
}

/* 
module "consul" {
  source               = "./modules/consul_server"
  deployment_id        = local.deployment_id
  owner                = var.owner
  instance_type        = var.instance_type
  public_subnets       = module.infra.public_subnets
  aws_keypair_name     = module.infra.aws_keypair_name
  bastion_sg_id        = module.infra.bastion_sg_id
  nomad_sg_id          = module.infra.nomad_sg_id
  consul_sg_id         = module.infra.consul_sg_id
  iam_instance_profile = module.infra.iam_instance_profile
  vpc_id               = module.infra.vpc_id
  elb                  = module.infra.elb
}
*/
