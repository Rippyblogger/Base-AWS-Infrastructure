module "networking" {
  source         = "./modules/networking"
  region         = "us-east-1"
  vpc_cidr_block = "10.0.0.0/16"
  public_subnets = {
    Main_public_1 = "10.0.0.0/18"
    Main_public_2 = "10.0.64.0/18"
  }
  private_subnets = {
    Main_private_1 = "10.0.128.0/18"
    Main_private_2 = "10.0.192.0/18"
  }
  cluster_name = "My_EKS_Cluster"
}

module "eks" {
  source          = "./modules/eks"
  cluster_name    = "My_EKS_Cluster"
  cluster_version = "1.32"
  node_group_name = "EKS_Node_group"
  private_subnets = module.networking.private_subnets
  vpc_cidr_block  = module.networking.vpc_cidr_block
  capacity_type   = "ON_DEMAND"
  instance_types        = ["t3.medium"]
  vpc_id = module.networking.vpc_id
  alb_security_group_id = module.load_balancer.lb_security_id
  instance_type = "t3.medium"
  ecr_repo_name = "golang_api"
}

module "load_balancer" {
  source          = "./modules/load_balancer"
  private_subnets = module.networking.private_subnets
  vpc_id          = module.networking.vpc_id
  vpc_cidr_block  = module.networking.vpc_cidr_block
  lb_logs_bucket_name = "lb-accesslogs25-bucket649823"
}

module "oidc" {
  source            = "./modules/oidc"
  github_branch     = "main"
  github_username   = "Rippyblogger"
  github_repository = "golang_api"
  eks_cluster_name = module.eks.cluster_name
}