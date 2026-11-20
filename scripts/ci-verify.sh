#!/usr/bin/env bash
# Complete all existing application and security paths without a release.
set -euo pipefail
status=0
just verify-backend || status=1
just verify-frontend || status=1
just security || status=1
exit "$status"
