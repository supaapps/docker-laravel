# Laravel docker

## Build And Runtime Images

The proposed v5 catalog in `images.json` provides separate `build` and `runtime`
images for PHP 8.2.35, 8.3.36 and 8.4.27 on native amd64/arm64. These releases
address [the PHP emergency vulnerabilities](https://www.php.net/archive/2026.php).
Publication requires all runtime, build, and security gates; catalog entries are
not evidence that a release has already been published.

The default `Dockerfile` uses digest-pinned Wolfi with signature-verified vendor
packages: libxml2 2.15.4 and ImageMagick 7.1.2.34. PHP and extension package versions
are pinned per branch. No private security patches or mixed-distribution binaries
are used. Transitive packages are resolved by the vendor's signed repository;
final SBOMs and image digests record the resolved dependency set.

| Profile | Contents | Intended use |
| --- | --- | --- |
| `php8.4-build-20261022.1` (also 8.2/8.3) | Runtime plus Composer, compiler, PHP headers, phpize, PECL, Git and Xdebug | Build dependencies and custom extensions |
| `php8.4-runtime-20261022.1` (also 8.2/8.3) | PHP CLI, Apache/mod_php, required PHP extensions and image libraries | Web, queue and scheduled Artisan processes |

Build and runtime share the same vendor PHP and native libraries. The runtime
starts from the common stage, not the build stage: no compiler, development
headers, Composer, Git, PECL or Xdebug. Its shell and package manager remain for
operability; it is not described as distroless. Apache retains port 80, mod_php,
`/var/www/public`, and `.htaccess` support. The master runs as root and workers
use `www-data`, matching the previous process model; this is not a rootless image.
Some vendor runtime dependencies reference packages named `-dev`; their required
shared libraries and package records remain, while header, pkg-config and static
archive files are removed from the runtime. Package records are never hidden from
the security scanner.

### Migration Boundary

This is a major-version change, not an apt-compatible replacement. Wolfi uses
`apk`, PHP configuration lives in `/etc/php`, and `docker-php-ext-*` helpers are
not provided. Use vendor extension packages or standard phpize/configure/make
in the build image. Apache module/configuration paths and exact image-format
coverage may differ from Debian; SVG/PNG/JPEG/GIF are mandatory tested formats.
OpenEXR is intentionally unavailable. Run application-specific format and native
dependency tests before adoption. No cron daemon is included: run scheduled PHP
commands through your deployment's scheduler. Existing custom entrypoints must
be reviewed rather than copied blindly.

Copy application/vendor artifacts from build into runtime, not the compiler,
Composer or the entire builder filesystem. Use the matching PHP branch for both
stages; custom extensions must use the same ABI and library versions. Runtime
images include CLI PHP so queues can override the command with `php artisan ...`.

The original Debian compatibility recipe remains in `Dockerfile.debian` with its own
`tests/smoke.sh`. It is not part of the new publication catalog and is not claimed
to pass the current security gate. Existing published tags are never overwritten.
The workflow does not update `main`, `latest` or historical image aliases.

### Rebuild And Release Recovery

Wolfi's live signed package index may remove superseded pinned versions. A source
rebuild is therefore not guaranteed to remain installable indefinitely; retain
published image digests and SBOMs for deployment reproducibility. When a pin is
unavailable, update it deliberately and rerun the entire verification matrix.
Never relax version constraints or security gates to make a rebuild pass.

Each architecture is published only after its own tests and scan pass. Public
multi-architecture tags are assembled only after every matrix job passes. A
failed release can leave architecture tags or some completed variant tags behind.
Do not overwrite or delete those tags to rerun: record their digests, increment
the catalog's image-tag revision and release version, and publish from a new
reviewed commit/tag. Partial releases must not be presented as complete releases.
An already-published image is not rebuilt under the same tag.

Local verification of the default PHP 8.4 variant (Docker required):

```sh
python3 -m unittest discover -s tests -v
docker build --pull --target runtime -t local/runtime:test .
bash tests/maintained-smoke.sh local/runtime:test 8.4.27 runtime
docker build --pull --target build -t local/build:test .
bash tests/maintained-smoke.sh local/build:test 8.4.27 build
```

CI verifies loaded XML libraries, DOM/SimpleXML, PDO, required PHP extensions,
SVG/raster processing, EXR absence, Apache rewrites, HTTP/multipart, graceful stop,
and an actual compiled PHP extension in every build variant. Both profiles are
also tested with fresh Laravel installations (Laravel 12 on PHP 8.2 and Laravel
13 on PHP 8.3/8.4), including CLI boot and the HTTP health route. Both profiles are
scanned; image-security gates and SBOM artifacts remain mandatory. No blanket
exceptions are used. `security-exceptions.json` is package/version-specific and
expiring and cannot exempt either PHP emergency CVE.

Consumers must rebuild, test and restart all workers; publishing a base image
does not patch a running application or its Composer dependencies. PHP 8.3 is not
an automatic compatibility guarantee for older applications. PHP 8.2 reaches
upstream end of security support on 2026-12-31.

## Clone docker compose example to Laravel project

The historical generator below targets the legacy image layout; review and
adapt its output before using a v5 build/runtime image.

Go to Laravel project then run:

```sh
GITHUB_TOKEN=YOUR_TOKEN_HERE
curl -H "Authorization: token $GITHUB_TOKEN" \
  -L https://raw.githubusercontent.com/supaapps/docker-laravel/main/clone-example | bash $GITHUB_TOKEN
```
