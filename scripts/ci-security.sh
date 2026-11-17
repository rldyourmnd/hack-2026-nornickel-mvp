#!/usr/bin/env bash
# Keep the independent security results after an earlier failure.
set -euo pipefail
status=0
just check-workflows || status=1
osv-scanner scan source --recursive . || status=1
exit "$status"
