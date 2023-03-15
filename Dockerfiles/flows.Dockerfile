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
    echo -e $GCP_SERVICE_ACCOUNT_API_KEY >> ~/gcp-credentials.json

RUN cat ~/gcp-credentials.json

RUN mkdir ~/.dbt && \
    touch ~/.dbt/profiles.yml && \
    echo "nyc-stats:" >> ~/.dbt/profiles.yml && \
    echo "  outputs:" >> ~/.dbt/profiles.yml && \
    echo "    dev:" >> ~/.dbt/profiles.yml && \
    echo "      dataset: ${GCP_DATASET_NAME}" >> ~/.dbt/profiles.yml && \
    echo "      job_execution_timeout_seconds: 300" >> ~/.dbt/profiles.yml && \
    echo "      job_retries: 1" >> ~/.dbt/profiles.yml && \
    echo "      keyfile: ~/gcp-credentials.json" >> ~/.dbt/profiles.yml && \
    echo "      location: ${GCP_RESOURCE_REGION}" >> ~/.dbt/profiles.yml && \
    echo "      method: service-account" >> ~/.dbt/profiles.yml && \
    echo "      priority: interactive" >> ~/.dbt/profiles.yml && \
    echo "      project: ${GCP_PROJECT_ID}" >> ~/.dbt/profiles.yml && \
    echo "      threads: 4" >> ~/.dbt/profiles.yml && \
    echo "      type: bigquery" >> ~/.dbt/profiles.yml && \
    echo "  target: dev" >> ~/.dbt/profiles.yml

RUN cat ~/.dbt/profiles.yml

WORKDIR pipeline

COPY pyproject.toml poetry.lock ./

RUN curl -sSL https://install.python-poetry.org | python - \
  && poetry config virtualenvs.create false --local \
  && poetry install --without dev --no-root
