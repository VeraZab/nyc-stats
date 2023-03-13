resource "google_artifact_registry_repository" "nyc-stats" {
  repository_id = "nyc-stats"
  location      = var.GCP_REGION
  format        = "docker"
}