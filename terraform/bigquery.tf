resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.GCP_DATASET_NAME
  project    = var.GCP_PROJECT_ID
  location   = var.GCP_REGION
}