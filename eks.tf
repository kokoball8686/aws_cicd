module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "cicd-cluster-v2"
  cluster_version = "1.27"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true
  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      min_size     = 1
      max_size     = 1
      desired_size = 1
      instance_types = ["t3.small"]
      disk_size    = 20
      capacity_type = "ON_DEMAND"
      
      tags = {
        "kubernetes.io/cluster/cicd-cluster-v2" = "owned"
        Environment = "dev"
        Terraform   = "true"
      }
    }
  }

  cluster_security_group_additional_rules = {
    ingress_jenkins = {
      description = "Jenkins to EKS cluster API"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      source_security_group_id = aws_security_group.jenkins_sg.id
    }
  }
} 