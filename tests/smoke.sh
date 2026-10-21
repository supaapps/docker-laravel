#!/usr/bin/env bash
set -euo pipefail
image=${1:?image required}
expected=${2:?PHP version required}
extensions=${3:-imagick,redis,xdebug,zip,pdo_mysql,mysqli,gd}
container="php-image-smoke-${RANDOM}-${RANDOM}"
cleanup() { docker rm -f "$container" >/dev/null 2>&1 || true; }
trap cleanup EXIT
docker run --rm "$image" php -r '
if (PHP_VERSION !== $argv[1]) { throw new RuntimeException("Unexpected PHP version: " . PHP_VERSION); }
foreach (explode(",", $argv[2]) as $extension) {
    if (!extension_loaded($extension)) { throw new RuntimeException("Missing extension: " . $extension); }
}
if (ini_get("session.upload_progress.enabled")) { throw new RuntimeException("Upload progress must be disabled"); }
echo PHP_VERSION, " ", PHP_SAPI, PHP_EOL;
' "$expected" "$extensions"
docker run --rm "$image" composer --version --no-ansi
docker run --rm "$image" apache2ctl -t
docker run --rm -i "$image" php < tests/features.php
docker run --rm "$image" sh -ec '
    for package in libmcrypt-dev libmagickwand-dev libzip-dev libpq-dev; do
        status=$(dpkg-query -W -f="\${db:Status-Status}" "$package" 2>/dev/null || true)
        test "$status" != installed || { echo "Unexpected build-only package: $package" >&2; exit 1; }
    done
'
docker build --pull=false -t local/downstream-smoke:test -f tests/downstream/Dockerfile .
docker create --name "$container" -p 127.0.0.1::80 "$image" >/dev/null
docker cp tests/http.php "$container:/var/www/public/image-smoke.php"
docker start "$container" >/dev/null
port=$(docker port "$container" 80/tcp)
url="http://${port}/image-smoke.php"
response=$(curl --fail --silent --show-error --retry 20 --retry-all-errors --retry-delay 1 --connect-timeout 2 --max-time 5 "$url")
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d["version"]==sys.argv[2]; assert d["method"]=="GET"; assert not d["upload_progress"]' "$response" "$expected"
response=$(printf 'disposable-upload' | curl --fail --silent --show-error -F 'field=smoke' -F 'upload=@-;filename=smoke.txt' "$url")
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d["method"]=="POST"; assert d["field"]=="smoke"; assert d["upload"]=="disposable-upload"' "$response"
