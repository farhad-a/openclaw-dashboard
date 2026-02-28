FROM nikolaik/python-nodejs:python3.14-nodejs25-slim

ENV PYTHONUNBUFFERED=1
ENV HOME=/home/dashboard
ENV OPENCLAW_HOME=/home/dashboard/.openclaw

RUN corepack enable

# Remap base image's 'pn' user to UID/GID 2000 to avoid conflicts with the dashboard user
RUN usermod -u 2000 pn && groupmod -g 2000 pn

WORKDIR /app

# Install system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash curl git gosu jq procps && \
    rm -rf /var/lib/apt/lists/*

# Install openclaw CLI
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install -g openclaw && \
    pnpm store prune

RUN useradd -r -u 998 dashboard && \
    mkdir -p ${OPENCLAW_HOME} && \
    chown -R dashboard:dashboard /app ${HOME}

COPY --chown=dashboard:dashboard index.html server.py refresh.sh themes.json /app/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x refresh.sh /entrypoint.sh

VOLUME ["${OPENCLAW_HOME}"]

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/')" || exit 1

# Default to root so entrypoint can adjust UID/GID, then step down
# Override with PUID/PGID env vars at runtime
ENTRYPOINT ["/entrypoint.sh"]
CMD ["python3", "server.py", "--bind", "0.0.0.0", "--port", "8080"]
