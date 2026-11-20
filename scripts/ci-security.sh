#!/usr/bin/env bash
# Source and native security share each check and preserve independent failures.
set -euo pipefail
mode=${1:-native}
case "$mode" in
  source | native) ;;
  *) printf '%s\n' 'Choose source or native security checks.' >&2; exit 2 ;;
esac
status=0
just --fmt --check || status=1
git diff --check HEAD || status=1
python3 -m json.tool .github/hosted-tools.json >/dev/null || status=1
actionlint || status=1
zizmor --offline --no-progress .github || status=1
bash -n scripts/ci-security.sh scripts/ci-verify.sh || status=1
shellcheck scripts/ci-security.sh scripts/ci-verify.sh || status=1
betterleaks git --no-banner --redact --log-opts=--all . || status=1
if [[ $mode == native ]]; then
  osv-scanner scan source --recursive . || status=1
fi
exit "$status"
