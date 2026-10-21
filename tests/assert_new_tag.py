"""Never confuse registry authentication/network errors with a missing tag."""
import subprocess
import sys


def assert_missing(returncode, message):
    if returncode == 0:
        raise ValueError("Refusing to overwrite an existing release tag")
    if not any(marker in message.lower() for marker in ["manifest unknown", "no such manifest"]):
        raise ValueError("Cannot establish tag absence: " + message)


if __name__ == "__main__":
    result = subprocess.run(["docker", "manifest", "inspect", sys.argv[1]], capture_output=True, text=True)
    assert_missing(result.returncode, result.stderr + result.stdout)
