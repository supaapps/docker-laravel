#!/usr/bin/env bash
set -euo pipefail
image=${1:?image required}
version=${2:?Laravel constraint required}
container="laravel-smoke-${RANDOM}-${RANDOM}"
trap 'docker rm -f "$container" >/dev/null 2>&1 || true' EXIT
docker build --pull=false --build-arg "TEST_IMAGE=$image" --build-arg "LARAVEL_VERSION=$version" \
    -f tests/laravel/Dockerfile -t local/laravel-smoke:test .
docker run --rm local/laravel-smoke:test php artisan about --only=environment
docker create --name "$container" -p 127.0.0.1::80 \
    -e SESSION_DRIVER=array -e CACHE_STORE=array -e APP_DEBUG=false local/laravel-smoke:test >/dev/null
docker start "$container" >/dev/null
port=$(docker port "$container" 80/tcp)
curl --fail --silent --show-error --retry 20 --retry-all-errors --retry-delay 1 \
    --connect-timeout 2 --max-time 10 "http://${port}/up"
docker stop --timeout 10 "$container" >/dev/null
test "$(docker inspect --format '{{.State.ExitCode}}' "$container")" = 0
