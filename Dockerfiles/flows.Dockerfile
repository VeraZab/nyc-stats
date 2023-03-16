FROM python:3.11

ENV PATH="/root/.local/bin:${PATH}"

ARG PREFECT_API_KEY
ENV PREFECT_API_KEY=$PREFECT_API_KEY

ARG PREFECT_API_URL
ENV PREFECT_API_URL=$PREFECT_API_URL

ARG PREFECT_GCP_CREDENTIALS_BLOCK_NAME
ENV PREFECT_GCP_CREDENTIALS_BLOCK_NAME=$PREFECT_GCP_CREDENTIALS_BLOCK_NAME

ARG GCP_DATASET_NAME
ENV GCP_DATASET_NAME=$GCP_DATASET_NAME

ARG GCP_DATASET_TABLE_NAME
ENV GCP_DATASET_TABLE_NAME=$GCP_DATASET_TABLE_NAME

ARG GCP_PROJECT_ID
ENV GCP_PROJECT_ID=$GCP_PROJECT_ID

ARG GCP_RESOURCE_REGION
ENV GCP_RESOURCE_REGION=$GCP_RESOURCE_REGION

ARG GCP_PRIVATE_KEY_ID
ENV GCP_PRIVATE_KEY_ID=$GCP_PRIVATE_KEY_ID

ARG GCP_PRIVATE_KEY
ENV GCP_PRIVATE_KEY=$GCP_PRIVATE_KEY

ARG GCP_SERVICE_ACCOUNT_EMAIL
ENV GCP_SERVICE_ACCOUNT_EMAIL=$GCP_SERVICE_ACCOUNT_EMAIL

ARG GCP_SERVICE_ACCOUNT_ID
ENV GCP_SERVICE_ACCOUNT_ID=$GCP_SERVICE_ACCOUNT_ID

ARG GCP_CLIENT_X509_CERT_URL
ENV GCP_CLIENT_X509_CERT_URL=$GCP_CLIENT_X509_CERT_URL

ENV PYTHONUNBUFFERED True

RUN apt-get update -qq && \
  apt-get -qq install \
  curl \
  jq

WORKDIR pipeline

COPY pyproject.toml poetry.lock ./

RUN curl -sSL https://install.python-poetry.org | python - \
  && poetry config virtualenvs.create false --local \
  && poetry install --without dev --no-root

RUN touch gcp-credentials.json && \
    echo '{' >> gcp-credentials.json && \
    echo '  "type": "service_account",' >> gcp-credentials.json && \
    echo '  "project_id": ${GCP_PROJECT_ID},' >> gcp-credentials.json && \
    echo '  "private_key_id": ${GCP_PRIVATE_KEY_ID},' >> gcp-credentials.json && \
    echo '  "private_key": $(GCP_PRIVATE_KEY),' >> gcp-credentials.json && \
    echo '  "client_email": $(GCP_SERVICE_ACCOUNT_EMAIL),' >> gcp-credentials.json && \
    echo '  "client_id": $(GCP_SERVICE_ACCOUNT_ID),' >> gcp-credentials.json && \
    echo '  "auth_uri": "https://accounts.google.com/o/oauth2/auth",' >> gcp-credentials.json && \
    echo '  "token_uri": "https://oauth2.googleapis.com/token",' >> gcp-credentials.json && \
    echo '  "token_uri": "https://oauth2.googleapis.com/token",' >> gcp-credentials.json && \
    echo '  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",' >> gcp-credentials.json && \
    echo '  "client_x509_cert_url": $(GCP_CLIENT_X509_CERT_URL)' >> gcp-credentials.json && \
    echo '}' >> gcp-credentials.json

RUN touch profiles.yml && \
    echo "nyc_stats:" >> profiles.yml && \
    echo "  outputs:" >> profiles.yml && \
    echo "    dev:" >> profiles.yml && \
    echo "      dataset: ${GCP_DATASET_NAME}" >> profiles.yml && \
    echo "      job_execution_timeout_seconds: 300" >> profiles.yml && \
    echo "      job_retries: 1" >> profiles.yml && \
    echo "      keyfile: ${PWD}/gcp-credentials.json" >> profiles.yml && \
    echo "      location: ${GCP_RESOURCE_REGION}" >> profiles.yml && \
    echo "      method: service-account" >> profiles.yml && \
    echo "      priority: interactive" >> profiles.yml && \
    echo "      project: ${GCP_PROJECT_ID}" >> profiles.yml && \
    echo "      threads: 4" >> profiles.yml && \
    echo "      type: bigquery" >> profiles.yml && \
    echo "  target: dev" >> profiles.yml