# CI

The shared jobs call the same Just commands as local maintenance. Backend and
frontend stay parallel on the public Ubuntu executor. The existing aggregate
gate requires successful backend, frontend, workflow/security and merge-stop
results.

`just setup-source` installs frozen binary dependencies without installing or
building the project and disables npm lifecycle scripts. `just check` only
checks metadata, lint, types, workflow safety and Git history. Set the standard
UV_PROJECT_ENVIRONMENT consistently for setup-source and check to keep a
source environment separate from a native environment. It runs no
application, pytest, evaluation or frontend build.

`just setup` prepares the original locked native environment. The backend
job keeps Ruff, strict mypy and the complete pytest suite. It also calls the
existing deterministic evaluation with LLM and external retrieval off; the
script uses its own temporary DuckDB and receives no `--store` option.
The frontend keeps typecheck and the original Vite build.

The workflow/security job audits workflows, scans the dependency locks and
redacts credential findings across all Git refs. Public tool artifacts are
declared by immutable release asset, digest and executable/member identity.
No per-job installer script is kept. A later failing gate cannot turn an
earlier failure into success.

The existing Make maintenance commands forward to Just. API, web, fixture,
reindex, warmup and Compose operations retain their existing definitions.
No fixture generation, real provider evaluation, optional ingest/model
qualification, runtime-data write, operator activation or deployment is part
of CI. A passing default test environment does not qualify omitted extras.
