#!/usr/bin/env bash
set -euo pipefail
image=${1:?image required}
expected=${2:?version required}
profile=${3:?profile required}
container="php-maintained-${RANDOM}-${RANDOM}"
trap 'docker rm -f "$container" >/dev/null 2>&1 || true' EXIT
docker run --rm -i "$image" php /dev/stdin "$profile" "$expected" < tests/maintained.php
docker run --rm -i "$image" php < tests/features.php
docker run --rm "$image" httpd -t
docker run --rm "$image" sh -ec '
    apk info -e libxml2-16=2.15.4-r1
    apk info -e imagemagick-7=7.1.2.34-r0
    ! apk info | grep -Ei "^(openexr|libopenexr)(-|$)"
    ! find /usr/lib -iname "*openexr*.so*" -o -name exr.so | grep -q .
'
if [[ "$profile" == build ]]; then
    docker run --rm "$image" composer --version --no-ansi
    tar -C tests/probe -cf - config.m4 base_probe.c | docker run --rm -i "$image" sh -ec '
        mkdir /tmp/base-probe; cd /tmp/base-probe; tar -xf -
        phpize; ./configure --enable-base_probe; make -j2
        php -d extension=/tmp/base-probe/modules/base_probe.so -r '\''if (base_probe() !== "compiled") { exit(1); }'\''
    '
else
    docker run --rm "$image" sh -ec '
        for tool in gcc g++ cc make phpize php-config composer git pecl; do
            if command -v "$tool" >/dev/null 2>&1; then echo "Unexpected runtime tool: $tool" >&2; exit 1; fi
        done
        test ! -d /usr/include
        ! find /usr/lib -name "*.a" | grep -q .
        ! apk info | grep -E "(^linux-headers$|^build-base$)"
    '
fi
docker create --name "$container" -p 127.0.0.1::80 "$image" >/dev/null
docker cp tests/http.php "$container:/var/www/public/image-smoke.php"
docker cp tests/maintained.htaccess "$container:/var/www/public/.htaccess"
docker start "$container" >/dev/null
port=$(docker port "$container" 80/tcp)
url="http://${port}/rewritten-smoke"
response=$(curl --fail --silent --show-error --retry 20 --retry-all-errors --retry-delay 1 --connect-timeout 2 --max-time 5 "$url")
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d["version"]==sys.argv[2], d; assert d["method"]=="GET", d; assert not d["upload_progress"], d' "$response" "$expected"
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d["environment"]=="checked", d; assert d["request_environment"]=="checked", d' "$response"
headers=$(curl --fail --silent --show-error --compressed -D - -o /dev/null "$url")
grep -qi '^Expires:' <<< "$headers"
grep -qi '^Content-Encoding: gzip' <<< "$headers"
! grep -qi '^X-Powered-By:' <<< "$headers"
! grep -Ei '^Server:.*(PHP|[0-9]+\.[0-9]+)' <<< "$headers"
test "$(curl --silent --show-error -o /dev/null -w '%{http_code}' -X TRACE "$url")" = 405
test "$(curl --silent --show-error -o /dev/null -w '%{http_code}' "http://${port}/redirect-smoke")" = 302
response=$(printf 'disposable-upload' | curl --fail --silent --show-error -F 'field=smoke' -F 'upload=@-;filename=smoke.txt' "http://${port}/image-smoke.php")
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); assert d["method"]=="POST"; assert d["field"]=="smoke"; assert d["upload"]=="disposable-upload"' "$response"
docker stop --timeout 10 "$container" >/dev/null
test "$(docker inspect --format '{{.State.ExitCode}}' "$container")" = 0
logs=$(docker logs "$container" 2>&1)
grep -q '"GET /rewritten-smoke HTTP/1.1" 200 ' <<< "$logs"
