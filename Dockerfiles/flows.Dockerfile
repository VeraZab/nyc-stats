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

RUN touch ~/gcp-credentials.json && \
    echo $GCP_SERVICE_ACCOUNT_API_KEY >> ~/gcp-credentials.json

RUN cat ~/gcp-credentials.json

RUN mkdir ~/.dbt && \
    touch ~/.dbt/profiles.yml && \
    echo "nyc-stats:
    outputs:
        dev:
        dataset: ${GCP_DATASET_NAME}
        job_execution_timeout_seconds: 300
        job_retries: 1
        keyfile: ~/gcp-credentials.json
        location: ${GCP_RESOURCE_REGION}
        method: service-account
        priority: interactive
        project: ${GCP_PROJECT_ID}
        threads: 4
        type: bigquery
    target: dev" >> ~/.dbt/profiles.yml

RUN cat ~/.dbt/profile

WORKDIR pipeline

COPY pyproject.toml poetry.lock ./

RUN curl -sSL https://install.python-poetry.org | python - \
  && poetry config virtualenvs.create false --local \
  && poetry install --without dev --no-root