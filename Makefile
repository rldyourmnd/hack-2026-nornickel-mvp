.PHONY: install test lint typecheck api web demo eval generate-fixtures docker-up docker-down ci reindex warmup

install:
	just setup

lint:
	just check

typecheck:
	just check

test:
	just test

api:
	uv run fastapi dev services/api/main.py --host 0.0.0.0 --port 8000

web:
	cd apps/web && npm run dev -- --host 0.0.0.0 --port 5173

generate-fixtures:
	uv run --extra fixtures python scripts/generate_synthetic_docs.py

eval:
	just eval

reindex:
	uv run python scripts/reindex.py

warmup:
	uv run python scripts/warmup.py

docker-up:
	docker compose up --build

docker-down:
	docker compose down

demo: docker-up

ci:
	just verify
