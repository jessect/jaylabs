# Everything here runs offline against a mocked azurerm provider: no Azure account needed.
.DEFAULT_GOAL := help
.PHONY: help init fmt validate test test-unit test-apply test-validation test-verbose naive mistakes mistake blind-spots break unbreak clean

help: ## List the targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-16s %s\n", $$1, $$2}'

init: ## Download the providers (azurerm, random)
	terraform init -input=false

fmt: ## Check formatting of every .tf and .tftest.hcl file
	terraform fmt -check -recursive

validate: ## Validate the configuration (no credentials needed)
	terraform validate

test: ## Run every test in tests/ with the mocked provider
	terraform test

test-unit: ## Plan-mode tests only: names, tags, NSG rules, hardening
	terraform test -filter=tests/unit.tftest.hcl

test-apply: ## Apply-mode tests only: ids, wiring, outputs
	terraform test -filter=tests/apply.tftest.hcl

test-validation: ## Bad input must fail (expect_failures)
	terraform test -filter=tests/validation.tftest.hcl

test-verbose: ## Run the tests and print the plan/state of every run
	terraform test -verbose

naive: ## What happens WITHOUT mocks: the real provider tries to log in to Azure
	cd examples/naive-provider && terraform init -input=false >/dev/null && \
	  AZURE_CONFIG_DIR=$$(mktemp -d) terraform test

mistakes: ## Reproduce every error from the video (all 7 fail on purpose)
	cd examples/common-mistakes && terraform init -input=false >/dev/null && terraform test

mistake: ## Run just one of them, e.g. make mistake N=02
	@cd examples/common-mistakes && terraform init -input=false >/dev/null && \
	  f=$$(ls tests/$(N)_*.tftest.hcl) && echo "terraform test -filter=$$f" && terraform test -filter=$$f

blind-spots: ## Tests that pass on mocks but would fail on real Azure
	cd examples/mock-blind-spots && terraform init -input=false >/dev/null && terraform test

break: ## Open SSH (port 22) instead of HTTPS in the NSG, to watch the tests catch it
	@sed -i 's/destination_port_range     = "443"/destination_port_range     = "22"/' network.tf
	@grep -n 'destination_port_range     = "22"' network.tf

unbreak: ## Put HTTPS (443) back
	@sed -i 's/destination_port_range     = "22"/destination_port_range     = "443"/' network.tf
	@grep -n 'destination_port_range     = "443"' network.tf

clean: ## Remove .terraform folders and lock files
	rm -rf .terraform .terraform.lock.hcl examples/*/.terraform examples/*/.terraform.lock.hcl
