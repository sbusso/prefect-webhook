FROM python:3.12-slim-bullseye AS base

ENV PYTHONUNBUFFERED=1 \
  PYTHONDONTWRITEBYTECODE=1 \
  PIP_NO_CACHE_DIR=off \
  PIP_DISABLE_PIP_VERSION_CHECK=on \
  PIP_DEFAULT_TIMEOUT=100 \
  POETRY_HOME="/opt/poetry" \
  POETRY_VIRTUALENVS_IN_PROJECT=true \
  POETRY_NO_INTERACTION=1 \
  VENV_PATH="/opt/pysetup/.venv" \
  PATH="$VENV_PATH/bin:$PATH" \
  PYSETUP_PATH="/opt/pysetup"

ARG POETRY_VERSION=1.7.1

ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"


FROM base AS builder

RUN apt-get update \
  && apt-get install --no-install-recommends -y build-essential curl libpq-dev python-dev

# Install Poetry
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -sSL https://install.python-poetry.org | POETRY_HOME=${POETRY_HOME} python3 - --version ${POETRY_VERSION} && \
  chmod a+x /opt/poetry/bin/poetry


WORKDIR $PYSETUP_PATH
COPY poetry.lock pyproject.toml ./

RUN poetry install --no-dev --no-interaction --no-ansi

FROM base AS production

WORKDIR /deploy

COPY --from=builder $PYSETUP_PATH $PYSETUP_PATH
COPY ./ /deploy/

CMD exec uvicorn prefect_webhook.main:app --host 0.0.0.0 --port $PORT
