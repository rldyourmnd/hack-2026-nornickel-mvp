set shell := ["bash", "-euo", "pipefail", "-c"]

# Lists the project commands.
default:
    @just --list

# Installs the frozen native backend and frontend environment on the executor.
setup: setup-backend setup-frontend

# Prepares only binary source dependencies without project builds or lifecycle scripts.
setup-source:
    uv sync --locked --group dev --no-install-project --no-build
    npm --prefix apps/web ci --ignore-scripts --no-audit

# Checks metadata, lint, types and history without building or running the application.
check: check-workflows check-backend check-frontend

# Checks the existing strict backend lint and type contracts.
check-backend:
    uv run --no-sync ruff check .
    MYPYPATH=src uv run --no-sync mypy

# Checks the existing frontend type contract.
check-frontend:
    npm --prefix apps/web run typecheck

# Checks commands, workflows, shell helpers and the complete Git history.
check-workflows:
    just --fmt --check
    git diff --check HEAD
    python3 -m json.tool .github/hosted-tools.json >/dev/null
    actionlint
    zizmor --offline --no-progress .github
    bash -n scripts/ci-security.sh scripts/ci-verify.sh
    shellcheck scripts/ci-security.sh scripts/ci-verify.sh
    betterleaks git --no-banner --redact --log-opts=--all .

# Runs the full original pytest suite on the executor.
test:
    uv run --no-sync pytest

# Runs the existing deterministic evaluation in its temporary ledger, without storing results.
eval:
    LLM_ENABLED=false EMBEDDING_BACKEND=off RERANKER_ENABLED=false uv run --no-sync python scripts/run_eval.py

# Builds the existing frontend on the executor.
build:
    npm --prefix apps/web run build

# Runs every workflow, dependency and credential security gate.
security:
    bash scripts/ci-security.sh

# Runs the complete backend, deterministic evaluation, frontend and security paths.
verify:
    bash scripts/ci-verify.sh

# Prepares the original locked backend environment, including the project.
[private]
setup-backend:
    uv sync --locked --group dev

# Prepares the original locked frontend environment.
[private]
setup-frontend:
    npm --prefix apps/web ci --no-audit

# Runs the complete offline backend graph.
[private]
verify-backend: check-backend test eval

# Runs the complete frontend graph.
[private]
verify-frontend: check-frontend build
