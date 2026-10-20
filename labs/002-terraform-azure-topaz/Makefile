# Every target runs with the lab's own Azure CLI profile (.azure/ in this folder),
# so your real `az login` is never used. For plain terraform/az commands: source env.sh
export AZURE_CONFIG_DIR := $(CURDIR)/.azure
export AZURE_CORE_INSTANCE_DISCOVERY := false
export AZURE_CORE_COLLECT_TELEMETRY := false
export REQUESTS_CA_BUNDLE := /etc/ssl/certs/ca-certificates.crt

TOPAZ   := https://127.0.0.1:8899
PROJECT := jaylabs-lab002
STORAGE := $(subst -,,st$(PROJECT))
HOSTS   := topaz.local.dev kv-$(PROJECT).vault.topaz.local.dev \
           $(STORAGE).blob.storage.topaz.local.dev $(STORAGE).queue.storage.topaz.local.dev \
           $(STORAGE).table.storage.topaz.local.dev sb-$(PROJECT).servicebus.topaz.local.dev

.PHONY: up health hosts cert login init apply check plan destroy down naive v5 v5-clean

up: ## Start Topaz and wait until it is healthy
	docker compose up -d
	$(MAKE) health

health: ## Wait until Topaz answers on port 8899 (works before `make hosts`)
	@until curl -skf $(TOPAZ)/health >/dev/null; do sleep 1; done
	@curl -sk $(TOPAZ)/health | jq '{status, version, runningMode}'

hosts: ## One time (sudo): resolve the Topaz hostnames to 127.0.0.1
	@grep -q 'jaylabs-lab002-topaz' /etc/hosts && echo "/etc/hosts already has the Topaz names" || \
	  echo "127.0.0.1 $(HOSTS) # jaylabs-lab002-topaz" | sudo tee -a /etc/hosts

cert: ## One time (sudo): trust the Topaz TLS certificate
	docker compose cp topaz:/app/topaz.crt ./topaz.crt
	sudo cp topaz.crt /usr/local/share/ca-certificates/topaz.crt
	sudo update-ca-certificates

login: ## Register the Topaz cloud in the lab's az profile and log in with the built-in fake user
	-az cloud register -n Topaz --cloud-config @topaz-cloud.json 2>/dev/null
	az cloud set -n Topaz
	az login --username topazadmin@topaz.local.dev --password admin --allow-no-subscriptions -o table

init:
	terraform init

apply: ## One resource at a time: parallel writes corrupt Topaz's state (README, error 7)
	terraform apply -auto-approve -parallelism=1

check:
	./scripts/check.sh

plan:
	terraform plan

destroy:
	terraform destroy -auto-approve -parallelism=1

down: ## Stop Topaz (everything in it is lost)
	docker compose down -v

naive: ## A provider block without metadata_host, run with an EMPTY az profile (never your real one)
	cd examples/naive-provider && terraform init -input=false && \
	  AZURE_CONFIG_DIR=$$(mktemp -d) terraform plan

v5: ## Same Topaz settings with azurerm 5.x: the storage account fails (README, error 3)
	cd examples/azurerm-v5 && terraform init -input=false -upgrade && \
	  terraform apply -auto-approve -parallelism=1

v5-clean: ## Remove what `make v5` left behind (terraform destroy fails on 5.x too)
	-az group delete -n rg-jaylabs-lab002-v5 --yes
	rm -f examples/azurerm-v5/terraform.tfstate*
