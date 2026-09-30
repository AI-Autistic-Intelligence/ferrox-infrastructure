provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# 1. VPC Network
resource "google_compute_network" "ferrox_vpc" {
  name                    = "ferrox-production-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "ferrox_subnet" {
  name          = "ferrox-private-subnet"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.gcp_region
  network       = google_compute_network.ferrox_vpc.id
}

# 2. Cloud SQL (PostgreSQL for Ferrox-PHP)
resource "google_sql_database_instance" "ferrox_db" {
  name             = "ferrox-core-db"
  database_version = "POSTGRES_15"
  region           = var.gcp_region

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.ferrox_vpc.id
    }
  }
}

# 3. Memorystore (Redis for Ferrox-Py Streaming)
resource "google_redis_instance" "ferrox_redis" {
  name           = "ferrox-redis"
  tier           = "BASIC"
  memory_size_gb = 1
  region         = var.gcp_region
  authorized_network = google_compute_network.ferrox_vpc.id
  redis_version  = "REDIS_7_0"
}

# 4. GKE (Google Kubernetes Engine) for Microservices
resource "google_container_cluster" "ferrox_cluster" {
  name     = "ferrox-k8s-cluster"
  location = var.gcp_region
  
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = google_compute_network.ferrox_vpc.id
  subnetwork               = google_compute_subnetwork.ferrox_subnet.id
}

resource "google_container_node_pool" "ferrox_nodes" {
  name       = "ferrox-node-pool"
  location   = var.gcp_region
  cluster    = google_container_cluster.ferrox_cluster.name
  node_count = 2

  node_config {
    machine_type = "e2-medium"
  }
}
