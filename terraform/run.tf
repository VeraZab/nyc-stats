resource "google_cloud_run_service" "run_service" {
  name     = "flow-infra"
  location = var.GCP_REGION

  template {
    spec {
      containers {
        image = "gcr.io/google-samples/hello-app:1.0"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}