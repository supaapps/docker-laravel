# Laravel docker

## Patched runtime variants

The release catalog in `images.json` pins PHP 8.2.35, 8.3.36, and 8.4.27
to upstream multi-architecture digests. These releases address
[CVE-2026-109618 and CVE-2026-109619](https://www.php.net/archive/2026.php#2026-10-21-5).

All new variants use Debian 13 (Trixie), matching the published `v4.0.2` OS
baseline. Older PHP image lines also require OS-level compatibility testing.

| Image tag | PHP | Purpose |
| --- | --- | --- |
| `php8.2-20261021.1` | 8.2.35 | Existing PHP 8.2 consumers |
| `php8.3-20261021.1` | 8.3.36 | Compatibility-tested upgrades from older runtimes |
| `php8.4-20261021.1`, `v4.0.3` | 8.4.27 | Existing PHP 8.4 consumers |

Images are published only after native amd64/arm64 HTTP, upload, extension, and
image-security checks. The workflow never updates `main`, `latest`, or historical
release image tags. Releases retain scan/SBOM workflow artifacts.

Existing images and deployments do not inherit security updates: consumers must
select a patched tag/digest, rebuild, test, and restart all workers. PHP 8.3 is not
a promise of compatibility with every older application. Historical `v1`/`v2`
directory layouts also require migration testing. PHP 8.2 reaches upstream end of
security support on 2026-12-31.

Local verification (Docker required):

```sh
python3 -m unittest discover -s tests -v
docker build --pull -t local/base-image:test .
bash tests/smoke.sh local/base-image:test 8.4.27
```

`security-exceptions.json` is an explicit, package/version-specific, expiring
review ledger. It cannot exempt either PHP runtime CVE. A runtime patch does not
resolve application Composer vulnerabilities.

## Clone docker compose example to Laravel project

Go to Laravel project then run:

```sh
GITHUB_TOKEN=YOUR_TOKEN_HERE
curl -H "Authorization: token $GITHUB_TOKEN" \
  -L https://raw.githubusercontent.com/supaapps/docker-laravel/main/clone-example | bash $GITHUB_TOKEN
```
