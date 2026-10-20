# Run `source scripts/emulators.env` first (see README).
SHELL := /bin/bash
.PHONY: up health init plan apply check destroy down naive

up: ## Start the five emulators
	docker compose up -d
	@$(MAKE) --no-print-directory health

health: ## Wait until every emulator answers
	@until curl -sf http://localhost:4443/_internal/healthcheck >/dev/null; do sleep 1; done; echo "fake-gcs  :4443 ok"
	@until curl -sf http://localhost:8085/ >/dev/null; do sleep 1; done; echo "pubsub    :8085 ok"
	@until curl -sf http://localhost:8080/ >/dev/null; do sleep 1; done; echo "firestore :8080 ok"
	@until curl -sf http://localhost:9020/v1/projects/x/instanceConfigs >/dev/null; do sleep 1; done; echo "spanner   :9020 ok"
	@until (echo > /dev/tcp/127.0.0.1/8086) 2>/dev/null; do sleep 1; done; echo "bigtable  :8086 ok"

init:
	terraform init

plan:
	terraform plan

apply:
	terraform apply -auto-approve

check:
	./scripts/check.sh

destroy:
	terraform destroy -auto-approve

down: ## Stop the emulators (all their data is lost)
	docker compose down
	rm -rf .gcloud-local

naive: ## Show what happens with a provider that has no local endpoints
	cd examples/naive-provider && terraform init -input=false && terraform plan
