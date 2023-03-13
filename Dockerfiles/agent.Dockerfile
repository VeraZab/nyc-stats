FROM python:3.11

ENV PATH="/root/.local/bin:${PATH}"

ARG PREFECT_API_KEY
ENV PREFECT_API_KEY=$PREFECT_API_KEY

ARG PREFECT_API_URL
ENV PREFECT_API_URL=$PREFECT_API_URL

ARG PREFECT_AGENT_QUEUE_NAME
ENV PREFECT_AGENT_QUEUE_NAME=$PREFECT_AGENT_QUEUE_NAME

RUN apt-get update -qq && \
  apt-get -qq install \
  curl

COPY pyproject.toml poetry.lock /

RUN curl -sSL https://install.python-poetry.org | python - \
  && poetry config virtualenvs.create false --local \
  && poetry install --without dev,flows --no-root

ENTRYPOINT ["sh", "-c", "prefect agent start --work-queue $PREFECT_AGENT_QUEUE_NAME"]