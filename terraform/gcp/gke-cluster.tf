provider "google" {
  project = "ferrox-global-production"
  region  = "europe-west1"
}

resource "google_container_cluster" "ferrox_gke" {
  name     = "ferrox-production-gke"
  location = "europe-west1"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {
    workload_pool = "ferrox-global-production.svc.id.goog"
  }
}

resource "google_container_node_pool" "ferrox_compute_pool" {
  name       = "ferrox-compute-pool"
  location   = "europe-west1"
  cluster    = google_container_cluster.ferrox_gke.name
  node_count = 2

  node_config {
    preemptible  = false
    machine_type = "c2-standard-8" # Compute optimized for high-throughput
    
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.ferrox_gke_sa.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    labels = {
      workload = "high-throughput"
    }
  }
}

resource "google_service_account" "ferrox_gke_sa" {
  account_id   = "ferrox-gke-sa"
  display_name = "Ferrox GKE Node Service Account"
}
