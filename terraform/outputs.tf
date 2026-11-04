output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = module.gke.cluster_endpoint
}

output "github_actions_service_account" {
  description = "Email of the CI/CD service account for GitHub Actions"
  value       = google_service_account.github_actions_sa.email
}

output "workload_identity_provider" {
  description = "The Workload Identity Provider resource name to use in GitHub Actions"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "artifact_registry_repo" {
  description = "Artifact Registry repository URL"
  value       = google_artifact_registry_repository.repo.repository_id
}