# passed in by env vars (TF_VAR)
variable "GCP_PROJECT_ID" {}
variable "GCP_REGION" {}
variable "GCP_DATASET_NAME" {}
variable "COMPUTE_ENGINE_NAME" {}
variable "COMPUTE_ENGINE_MACHINE_TYPE" {}
variable "COMPUTE_ENGINE_REGION" {}
variable "LOCAL_SERVICE_ACCOUNT_FILE_PATH" {}
variable "SERVICE_ACCOUNT_EMAIL" {}
variable "PREFECT_AGENT_QUEUE_NAME" {}
variable "PREFECT_API_KEY" {
  sensitive = true
}
variable "PREFECT_API_URL" {
  sensitive = true
}
