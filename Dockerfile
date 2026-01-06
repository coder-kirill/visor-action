# базовый образ
FROM python:3.11-slim

LABEL maintainer="coder-kirill" \
      org.opencontainers.image.source="https://github.com/coder-kirill/visor-action" \
      org.opencontainers.image.title="VISOR GitHub Action"

# env
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# зависимости
RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# копируем entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# рабочая директория
WORKDIR /github/workspace

# точка входа
ENTRYPOINT ["/entrypoint.sh"]
