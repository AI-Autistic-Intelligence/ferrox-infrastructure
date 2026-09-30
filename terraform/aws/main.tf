provider "aws" {
  region = var.aws_region
}

# 1. Networking (VPC & Subnets)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "ferrox-production-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

# 2. ElastiCache (Redis) for Ferrox-Py Streaming & Backpressure
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "ferrox-redis-cluster"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"
  port                 = 6379
  security_group_ids   = [aws_security_group.redis_sg.id]
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnets.name
}

resource "aws_elasticache_subnet_group" "redis_subnets" {
  name       = "ferrox-redis-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

# 3. RDS Postgres for Ferrox-PHP Core
resource "aws_db_instance" "ferrox_db" {
  identifier           = "ferrox-core-db"
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = "db.t4g.micro"
  db_name              = "ferrox"
  username             = var.db_username
  password             = var.db_password
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

resource "aws_db_subnet_group" "db_subnets" {
  name       = "ferrox-db-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

# 4. ECS Fargate Cluster for Microservices (PHP + Python)
resource "aws_ecs_cluster" "ferrox_cluster" {
  name = "ferrox-microservices-cluster"
}

# --- Note: Security Groups are defined below to allow internal traffic ---
resource "aws_security_group" "redis_sg" {
  name        = "ferrox-redis-sg"
  description = "Allow Redis inbound from VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

resource "aws_security_group" "db_sg" {
  name        = "ferrox-db-sg"
  description = "Allow PostgreSQL inbound from VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}
