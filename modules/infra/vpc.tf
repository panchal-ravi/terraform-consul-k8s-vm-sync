locals {
  key_name = "ssh_key"
}

data "http" "myip" {
  url = "http://ifconfig.me"
}

data "aws_availability_zones" "available" {}

resource "aws_key_pair" "this" {
  key_name   = "${var.deployment_id}-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh.private_key_openssh
  filename = "${path.root}/generated/${local.key_name}"

  provisioner "local-exec" {
    command = "chmod 400 ${path.root}/generated/${local.key_name}"
  }
}

module "bastion_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  name        = "${var.deployment_id}-bastion"
  description = "bastion inbound sg"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["ssh-tcp", "consul-webui-http-tcp", "consul-webui-https-tcp", "consul-dns-tcp", "consul-dns-udp"]
  ingress_cidr_blocks = ["${data.http.myip.response_body}/32"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

module "consul_sg" {
  source      = "terraform-aws-modules/security-group/aws//modules/consul"
  name        = "${var.deployment_id}-consul"
  description = "consul security group"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.13.0"

  name                 = var.deployment_id
  cidr                 = var.vpc_cidr
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = var.private_subnets
  public_subnets       = var.public_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${var.deployment_id}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.deployment_id}" = "shared"
    "kubernetes.io/role/elb"                     = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.deployment_id}" = "shared"
    "kubernetes.io/role/internal-elb"            = "1"
  }
}

resource "aws_iam_role" "instance_role" {
  name_prefix        = var.owner
  assume_role_policy = data.aws_iam_policy_document.instance_role.json
  inline_policy {
    name   = "${var.deployment_id}-metadata-access"
    policy = data.aws_iam_policy_document.metadata_access.json
  }
}

data "aws_iam_policy_document" "instance_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "metadata_access" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = var.owner
  role        = aws_iam_role.instance_role.name
}
