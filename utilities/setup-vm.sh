#!/bin/bash

# setup logging
curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh sudo bash install-logging-agent.sh

# install system req
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y \
    build-essential \
    curl \
    zlib1g-dev \
    libffi-dev \
    libssl-dev \
    libbz2-dev \
    libsqlite3-dev

# Download and compile Python 3.11 from source
wget https://www.python.org/ftp/python/3.11.0/Python-3.11.0.tgz
tar xzf Python-3.11.0.tgz
cd Python-3.11.0
./configure --enable-optimizations
make -j "$(nproc)"
sudo make altinstall
export PATH="/usr/local/lib/bin:$PATH"

# clone repo
cd /
git clone https://github.com/VeraZab/nyc-stats.git
cd nyc-stats

# create venv
python3.11 -m venv prefect-env
source prefect-env/bin/activate

# install poetry and dependencies
curl -sSL https://install.python-poetry.org | POETRY_HOME=/usr/local/lib python3.11 -
poetry install --no-root --without dev,flows

# set env vars
export PREFECT_API_KEY=`curl  -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/PREFECT_API_KEY"`
export PREFECT_API_URL=`curl  -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/PREFECT_API_URL"`
export PREFECT_AGENT_QUEUE_NAME=`curl  -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/PREFECT_AGENT_QUEUE_NAME"`

prefect agent start -q $PREFECT_AGENT_QUEUE_NAME