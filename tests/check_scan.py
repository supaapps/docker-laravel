"""Reject unreviewed high/critical vulnerabilities in the exact tested image."""
import datetime
import json
import sys

PHP_CVES = {"CVE-2026-109618", "CVE-2026-109619"}


def failures(report, exceptions, today):
    accepted = set()
    for item in exceptions:
        if not item.get("reason") or not item.get("package"):
            raise ValueError("Exceptions require a package, reason, and expiry")
        if datetime.date.fromisoformat(item["expires"]) < today:
            raise ValueError("Expired security exception: " + item["id"])
        if item["id"] in PHP_CVES:
            raise ValueError("The PHP runtime vulnerabilities cannot be excepted")
        accepted.add((item["id"], item["package"], item["installed_version"]))
    rejected = []
    for result in report.get("Results", []):
        for item in result.get("Vulnerabilities", []) or []:
            key = (item["VulnerabilityID"], item["PkgName"], item["InstalledVersion"])
            if key[0] in PHP_CVES or (item["Severity"] in {"HIGH", "CRITICAL"} and key not in accepted):
                rejected.append(key)
    return rejected


if __name__ == "__main__":
    with open(sys.argv[1]) as handle:
        report = json.load(handle)
    with open("security-exceptions.json") as handle:
        exceptions = json.load(handle)
    rejected = failures(report, exceptions, datetime.datetime.now(datetime.timezone.utc).date())
    for entry in rejected:
        print("UNRESOLVED", *entry)
    sys.exit(bool(rejected))
