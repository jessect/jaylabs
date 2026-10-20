# Run `source .venv/bin/activate` first (see README).
.PHONY: up health moto-up moto-down init apply check plan destroy down naive

up: ## Start LocalStack (needs LOCALSTACK_AUTH_TOKEN in .env)
	docker compose up -d
	$(MAKE) health

health: ## Wait until LocalStack answers on port 4566
	@until curl -sf http://localhost:4566/_localstack/health >/dev/null; do sleep 1; done
	@curl -s http://localhost:4566/_localstack/health | jq '.services | {s3, dynamodb, sqs, ec2, ssm, secretsmanager}'

moto-up: ## Start Moto in the background on the same port
	moto_server -p 4566 > moto.log 2>&1 & echo $$! > moto.pid
	@until curl -sf http://localhost:4566/moto-api/ >/dev/null; do sleep 1; done
	@echo "Moto is up (pid $$(cat moto.pid))"

moto-down: ## Stop Moto (all its state is lost)
	-kill $$(cat moto.pid) && rm -f moto.pid moto.log

init:
	terraform init

apply:
	terraform apply -auto-approve

check:
	./scripts/check.sh

plan:
	terraform plan

destroy:
	terraform destroy -auto-approve

down: ## Stop LocalStack and delete its data
	docker compose down -v
	sudo rm -rf volume  # LocalStack creates it as root

naive: ## Show what happens with a provider that has no local endpoints
	cd examples/naive-provider && terraform init -input=false && terraform plan
