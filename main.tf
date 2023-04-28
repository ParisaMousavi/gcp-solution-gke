resource "google_service_account" "default" {
  account_id   = "service-account-id"
  display_name = "Service Account"
}

resource "google_container_cluster" "primary" {
  name = "my-gke-cluster"
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  # node_config {
  #   preemptible  = true
  #   machine_type = "e2-medium"

  #   # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
  #   service_account = google_service_account.default.email
  #   oauth_scopes = [
  #     "https://www.googleapis.com/auth/cloud-platform"
  #   ]
  # }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool-2"
  cluster    = google_container_cluster.primary.name
  node_count = 1
  node_config {
    preemptible  = true
    spot         = false
    machine_type = "e2-medium"
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/userinfo.email"
    ]
  }
  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}


# gcloud iam service-accounts get-iam-policy technical-user-for-devops@dummy-parisa-2023.iam.gserviceaccount.com –format=json > policy.json


# PROJECT_ID="dummy-parisa-2023"

# gcloud iam service-accounts create technical-user-for-devops --description="Terraform Service account" --display-name="Terraform Service Account"

# gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:technical-user-for-devops@${PROJECT_ID}.iam.gserviceaccount.com" --role="roles/editor"

# gcloud iam service-accounts get-iam-policy "technical-user-for-devops@${PROJECT_ID}.iam.gserviceaccount.com" --format=json > policy.json

