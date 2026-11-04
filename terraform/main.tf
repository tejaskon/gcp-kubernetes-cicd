provider "google" {
  project = var.project_id
  region  = var.region
}

# --- VPC MODULE ---
module "vpc" {
  source     = "./modules/vpc"
  project_id = var.project_id
  region     = var.region
}

# --- LEAST PRIVILEGE GKE NODE SERVICE ACCOUNT ---
resource "google_service_account" "gke_nodes_sa" {
  account_id   = "gke-node-sa"
  display_name = "Least Privilege GKE Node SA"
}

resource "google_project_iam_member" "gke_node_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/artifactregistry.reader"
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.gke_nodes_sa.email}"
}

# --- GKE MODULE ---
module "gke" {
  source                     = "./modules/gke"
  project_id                 = var.project_id
  region                     = var.region
  network_name               = module.vpc.network_name
  subnet_name                = module.vpc.subnet_name
  node_service_account_email = google_service_account.gke_nodes_sa.email
}

# --- ARTIFACT REGISTRY ---
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "lab-repo"
  format        = "DOCKER"
}

# --- GITHUB ACTIONS WORKLOAD IDENTITY FEDERATION ---
resource "google_service_account" "github_actions_sa" {
  account_id   = "github-actions-sa"
  display_name = "GitHub Actions CI/CD SA"
}

resource "google_project_iam_member" "ci_cd_roles" {
  for_each = toset([
    "roles/artifactregistry.writer",
    "roles/container.developer"
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Pool"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.github_actions_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME"
}