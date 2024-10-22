variable "region" {
  default = "ap-southeast-1"
}

variable "vpc_cidr" {
  description = "AWS VPC CIDR"
  type        = string
  default     = "10.200.0.0/16"
}

variable "private_subnets" {
  description = "AWS private subnets"
  type        = list(any)
  default     = ["10.200.20.0/24", "10.200.21.0/24", "10.200.22.0/24"]
}

variable "public_subnets" {
  description = "AWS public subnets"
  type        = list(any)
  default     = ["10.200.10.0/24", "10.200.11.0/24", "10.200.12.0/24"]
}

variable "instance_type" {
  default = "t3.micro"
}

variable "owner" {
  default = "rp"
}


variable "aws_eks_cluster_version" {
  description = "AWS EKS cluster version"
  type        = string
  default     = "1.29"
}

variable "aws_eks_cluster_service_cidr" {
  description = "AWS EKS cluster service cidr"
  type        = string
  default     = "172.20.0.0/18"
}