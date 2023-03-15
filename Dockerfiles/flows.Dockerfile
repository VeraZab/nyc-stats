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

ARG GCP_SERVICE_ACCOUNT_API_KEY
ENV GCP_SERVICE_ACCOUNT_API_KEY=$GCP_SERVICE_ACCOUNT_API_KEY

ARG GCP_RESOURCE_REGION
ENV GCP_RESOURCE_REGION=$GCP_RESOURCE_REGION

ENV PYTHONUNBUFFERED True

RUN apt-get update -qq && \
  apt-get -qq install \
  curl

WORKDIR pipeline

COPY pyproject.toml poetry.lock ./

RUN curl -sSL https://install.python-poetry.org | python - \
  && poetry config virtualenvs.create false --local \
  && poetry install --without dev --no-root

RUN touch gcp-credentials.json && \
    echo -e $GCP_SERVICE_ACCOUNT_API_KEY >> gcp-credentials.json

RUN touch profiles.yml && \
    echo "nyc-stats:" >> profiles.yml && \
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