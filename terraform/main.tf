terraform {
  required_version = ">= 1.0"
  backend "local" {}  # Can change from "local" to "gcs" (for google) or "s3" (for aws), if you would like to preserve your tf-state online
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}

provider "google" {
  project = var.GCP_PROJECT_ID
  region = var.GCP_REGION
  credentials = file(var.LOCAL_SERVICE_ACCOUNT_FILE_PATH)
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.GCP_DATASET_NAME
  project    = var.GCP_PROJECT_ID
  location   = var.GCP_REGION
}

resource "google_compute_instance" "vm" {
  name         = var.COMPUTE_ENGINE_NAME
  machine_type = var.COMPUTE_ENGINE_MACHINE_TYPE
  zone         = var.COMPUTE_ENGINE_REGION
  tags = ["allow-external"]

  boot_disk {
    initialize_params {
      image = "ubuntu-2004-focal-v20230104"
    }
  }

  metadata = {
    "EXTERNAL_VM_IP" = google_compute_address.static.address
    "GCP_DATASET_NAME" = var.GCP_DATASET_NAME
    "REMOTE_SERVICE_ACCOUNT_FILE_PATH" = var.REMOTE_SERVICE_ACCOUNT_FILE_PATH
    "GCP_REGION" = var.GCP_REGION
    "GCP_PROJECT_ID" = var.GCP_PROJECT_ID
    "GCP_DATASET_TABLE_NAME" = var.GCP_DATASET_TABLE_NAME
    "DBT_PROFILE_NAME" = var.DBT_PROFILE_NAME
    "PREFECT_GCP_CREDENTIALS_BLOCK_NAME" = var.PREFECT_GCP_CREDENTIALS_BLOCK_NAME
    "PREFECT_AGENT_QUEUE" = var.PREFECT_AGENT_QUEUE
    "PREFECT_DBT_CORE_BLOCK_NAME" = var.PREFECT_DBT_CORE_BLOCK_NAME
    "PREFECT_GITHUB_BLOCK_NAME" = var.PREFECT_GITHUB_BLOCK_NAME
    "GITHUB_REPO_URL" = var.GITHUB_REPO_URL
  }

  metadata_startup_script = file("../utilities/setup-vm.sh")

  network_interface {
    network    = "default"
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  service_account {
    email  = var.SERVICE_ACCOUNT_EMAIL
    scopes = [
      "cloud-platform",
    ]
  }
}

resource "google_compute_firewall" "vm_firewall" {
  name    = "vm-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["4200"]
  }

  allow {
    protocol = "udp"
    ports    = ["4200"]
  }

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = google_compute_instance.vm.tags
}

resource "google_compute_address" "static" {
  name = "vm-external-address"
  address_type = "EXTERNAL"
}