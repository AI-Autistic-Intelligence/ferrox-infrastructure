# Ferrox Infrastructure (IaC)

![Platform](https://img.shields.io/badge/Platform-Polyglot-blue.svg)
![Infrastructure](https://img.shields.io/badge/Infrastructure-Terraform-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

**Ferrox Infrastructure** is the centralized "Infrastructure as Code" (IaC) repository for deploying the Ferrox Ecosystem. It implements a **Platform Engineering** approach, completely decoupling the underlying infrastructure from the microservices.

By using this repository, you provision the **Data Storage Layer** (PostgreSQL, Redis) and the **Compute Cluster**, into which all Ferrox Polyglot microservices (PHP, Python, Node.js, Java) are subsequently injected.

## 🏗️ Polyglot Architecture

The infrastructure orchestrates the following ecosystem:
1. **Ferrox-PHP (API Gateway)**: Handles REST ingress, zero-trust security (Paseto), and WAF. Reads from PostgreSQL.
2. **Ferrox-Py (Data Platform)**: Handles massive WebSocket multiplexing, DAG ETL pipelines, and Quantitative Analytics (Pandas/Numpy). Reads/Writes to Redis.
3. **Ferrox-Node (Real-Time)**: Handles outgoing WebSockets to clients.
4. **Ferrox-Java (Enterprise)**: Handles heavy transactional processing and Event Sourcing.

## 🚀 Deployment Scenarios

This repository contains ready-to-use Terraform modules for 3 different scenarios:

### 1. AWS (Amazon Web Services) - Serverless Enterprise
**Path:** `terraform/aws`
- Provisions an **ECS Fargate Cluster** for serverless container execution.
- Provisions **ElastiCache (Redis)** and **RDS (PostgreSQL)** within a private VPC network.
- *Best for:* Highly scalable, zero-ops production environments.

```bash
cd terraform/aws
terraform init
terraform apply -var="aws_region=eu-central-1" -var="db_password=YOUR_SECURE_PASSWORD"
```

### 2. GCP (Google Cloud Platform) - Kubernetes
**Path:** `terraform/gcp`
- Provisions a **GKE (Google Kubernetes Engine)** cluster.
- Provisions **Cloud SQL** and **Memorystore**.
- *Best for:* Teams relying on Kubernetes orchestration and Helm charts.

```bash
cd terraform/gcp
terraform init
terraform apply -var="gcp_project_id=your-project" -var="gcp_region=europe-west3"
```

### 3. VPS / Bare-Metal - Docker Swarm / Compose
**Path:** `terraform/vps`
- Uses `null_resource` to connect via SSH to a raw IP.
- Automatically installs Docker and Docker-Compose.
- Boots up the entire Polyglot Hub natively via a generated `docker-compose.yml`.
- *Best for:* Low-cost environments, on-premise servers, or staging.

```bash
cd terraform/vps
terraform init
terraform apply -var="vps_ip=192.168.1.100" -var="ssh_private_key_path=~/.ssh/id_rsa" -var="db_password=secret"
```

## 🔗 Integration via Git Submodules
To provide developers with immediate access to local deployment orchestration, this repository can be integrated into individual application repositories (e.g., `ferrox-php`, `ferrox-py`) as a Git Submodule:

```bash
# Inside your ferrox-php or ferrox-py repo:
git submodule add https://github.com/AI-Autistic-Intelligence/ferrox-infrastructure.git infrastructure
git commit -m "chore: link infrastructure submodule"
```

This allows developers to spin up the entire ecosystem dependencies (Postgres, Redis) locally using the VPS/Docker-Compose scripts before writing application code.
