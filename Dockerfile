FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1
ENV HOME=/home/dashboard
ENV OPENCLAW_HOME=/home/dashboard/.openclaw

WORKDIR /app

# Install system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash curl git gosu jq procps \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (for openclaw CLI)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
       | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
       > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && npm install -g openclaw \
    && apt-get purge -y gnupg && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /root/.npm

RUN useradd -r -u 998 dashboard && \
    mkdir -p /home/dashboard/.openclaw && \
    chown -R dashboard:dashboard /app /home/dashboard

COPY --chown=dashboard:dashboard index.html server.py refresh.sh themes.json ./
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x refresh.sh /entrypoint.sh

# Default to root so entrypoint can adjust UID/GID, then step down
# Override with PUID/PGID env vars at runtime

VOLUME ["/home/dashboard/.openclaw"]

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/')" || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["python3", "server.py", "--bind", "0.0.0.0", "--port", "8080"]
