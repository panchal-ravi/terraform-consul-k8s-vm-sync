
module "eks" {
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "~> 20.0"
  cluster_name                    = var.deployment_id
  cluster_version                 = var.cluster_version
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_service_ipv4_cidr       = var.cluster_service_cidr

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
  }

  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AmazonEKS_EBS_CSI_DriverRole"
    }
  }

  cluster_security_group_additional_rules = {
    ops_private_access_egress = {
      description = "Ops Private Egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["10.200.0.0/16"]
    }
    ops_private_access_ingress = {
      description = "Ops Private Ingress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = ["10.200.0.0/16"]
    }
  }


  eks_managed_node_groups = {
    demo = {
      min_size               = 1
      max_size               = 2
      desired_size           = 2
      instance_types         = ["t3.medium"]
      key_name               = aws_key_pair.this.key_name
      vpc_security_group_ids = [module.bastion_sg.security_group_id, module.consul_sg.security_group_id]
    }
  }

  tags = {
    owner = var.owner
  }
}


resource "null_resource" "kubeconfig" {

  provisioner "local-exec" {
    command = <<-EOT
      aws eks --region ${var.region} update-kubeconfig --kubeconfig ${path.root}/${var.deployment_id}-kubeconfig --name ${module.eks.cluster_name};
      EOT
  }

  depends_on = [
    module.eks
  ]
}


data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ebs-csi-role" {
  name = "AmazonEKS_EBS_CSI_DriverRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.eks.${var.region}.amazonaws.com/id/${split("/", module.eks.oidc_provider)[2]}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${module.eks.oidc_provider}:aud" : "sts.amazonaws.com",
            "${module.eks.oidc_provider}:sub" : "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ebs_csi_role_attach" {
  role       = aws_iam_role.ebs-csi-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
