FROM python:3.11

ENV PATH="/root/.local/bin:${PATH}"
RUN export PREFECT_API_KEY=`curl  -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/PREFECT_API_KEY"`
RUN export PREFECT_API_URL=`curl  -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/PREFECT_API_URL"`
RUN export PREFECT_AGENT_QUEUE_NAME=`curl  -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/PREFECT_AGENT_QUEUE_NAME"`

RUN apt-get update -qq && \
  apt-get -qq install \
  curl

COPY pyproject.toml poetry.lock /

RUN curl -sSL https://install.python-poetry.org | python - \
  && poetry config virtualenvs.create false --local \
  && poetry install --without dev,flows --no-root

ENTRYPOINT ["sh", "-c", "prefect agent start --work-queue $PREFECT_AGENT_QUEUE_NAME"]