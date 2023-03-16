include .env

####################################################################################################################
# Auto formatting, type checks, & Lint checks

format:
	python -m black -S --line-length 79 .

isort:
	isort .

lint: 
	flake8 ./flows

lint-and-format: isort format lint


####################################################################################################################
# Prefect

prefect-cloud-login:
	(\
		prefect cloud login -k $(PREFECT_KEY)\
	)

prefect-cloud-logout:
	prefect cloud logout

prefect-api-url:
	(\
		make prefect-cloud-login &&\
		prefect cloud workspace set --workspace $(PREFECT_WORKSPACE) &&\
		prefect config view &&\
		make prefect-cloud-logout\
	)

####################################################################################################################
# Google Cloud

service-account:
	gcloud iam service-accounts create $(GCP_SERVICE_ACCOUNT_NAME) --display-name="Terraform Service Account"

service-account-permissions:
	gcloud projects add-iam-policy-binding $(GCP_PROJECT_ID) --member='serviceAccount:$(GCP_SERVICE_ACCOUNT_NAME)@$(GCP_PROJECT_ID).iam.gserviceaccount.com' --role='roles/editor'

download-api-key:
	gcloud iam service-accounts keys create $(LOCAL_SERVICE_ACCOUNT_FILE_PATH) --iam-account=$(GCP_SERVICE_ACCOUNT_NAME)@$(GCP_PROJECT_ID).iam.gserviceaccount.com

enable-apis:
	gcloud services enable iam.googleapis.com \
		compute.googleapis.com \
		bigquery.googleapis.com \
		run.googleapis.com \
		artifactregistry.googleapis.com

gcp-setup:
	make enable-apis && service-account && make service-account-permissions && make download-api-key