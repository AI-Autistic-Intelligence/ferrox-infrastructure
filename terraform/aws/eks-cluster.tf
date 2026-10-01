module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "ferrox-production-eks"
  cluster_version = "1.30"

  cluster_endpoint_public_access  = true
  
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  eks_managed_node_groups = {
    # High frequency data ingestion (Rust / C++ / Python)
    ferrox_high_throughput = {
      min_size     = 2
      max_size     = 10
      desired_size = 2
      instance_types = ["c6i.2xlarge"] # Compute optimized
      capacity_type  = "ON_DEMAND"
      
      labels = {
        role = "ingestion"
      }
    }
    
    # Banking Core (Java ZGC / Memory Intensive)
    ferrox_memory_intensive = {
      min_size     = 2
      max_size     = 5
      desired_size = 2
      instance_types = ["r6i.2xlarge"] # Memory optimized
      capacity_type  = "ON_DEMAND"

      labels = {
        role = "core-banking"
      }
    }
  }

  enable_cluster_creator_admin_permissions = true
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "ferrox-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  intra_subnets   = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}
