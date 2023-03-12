resource "google_artifact_registry_repository" "flow-images" {
  repository_id = "flow-images"
  location      = var.GCP_REGION
  format        = "docker"
}

resource "google_artifact_registry_repository" "agent-images" {
  repository_id = "agent-images"
  location      = var.GCP_REGION
  format        = "docker"
}