#!/bin/bash
set -e

APP_PORT=${APP_PORT:-8000}

export XDG_RUNTIME_DIR=/run/user/$(id -u)

podman rm -f docker_app_1 2>/dev/null || true
podman rm -f docker_db_1  2>/dev/null || true

podman build --target production -t kubsu_app .

podman run -d \
    --name docker_db_1 \
    --network host \
    --restart unless-stopped \
    -v kubsu_postgres_data:/var/lib/postgresql/data \
    -e POSTGRES_USER=kubsu \
    -e POSTGRES_PASSWORD=kubsu \
    -e POSTGRES_DB=kubsu \
    postgres:16-alpine

echo "Waiting for postgres..."
for i in $(seq 1 30); do
    podman exec docker_db_1 pg_isready -U kubsu 2>/dev/null && break
    sleep 2
done

podman run -d \
    --name docker_app_1 \
    --network host \
    --restart unless-stopped \
    -e DATABASE_URL=postgresql+psycopg://kubsu:kubsu@127.0.0.1:5432/kubsu \
    -e APP_PORT="$APP_PORT" \
    kubsu_app
