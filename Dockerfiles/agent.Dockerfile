FROM python:3.11

ENV PATH="/root/.local/bin:${PATH}"
ENV PREFECT_API_KEY=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/PREFECT_API_KEY -H "Metadata-Flavor: Google")
ENV PREFECT_API_URL=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/PREFECT_API_URL -H "Metadata-Flavor: Google")
ENV PREFECT_AGENT_QUEUE_NAME=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/PREFECT_AGENT_QUEUE_NAME -H "Metadata-Flavor: Google")

RUN apt-get update -qq && \
  apt-get -qq install \
  curl

COPY pyproject.toml poetry.lock /

RUN curl -sSL https://install.python-poetry.org | python - \
  && poetry config virtualenvs.create false --local \
  && poetry install --no-dev --no-root

ENTRYPOINT ["sh", "-c", "prefect agent start --work-queue $PREFECT_AGENT_QUEUE_NAME"]