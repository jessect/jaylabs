# No cloud account needed: every target runs offline against a mocked provider.
.PHONY: help init fmt validate test test-verbose test-plan step naive naive-test clean
.DEFAULT_GOAL := help

help: ## List the targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  %-13s %s\n", $$1, $$2}'

init: ## Download the google + random providers (no credentials needed)
	terraform init -input=false

fmt: ## Format every .tf and .tftest.hcl file
	terraform fmt -recursive

validate: ## fmt check + validate (works without a GCP project)
	terraform fmt -check -recursive
	terraform validate

test: ## Run every test in tests/ with the mocked google provider
	terraform test

test-verbose: ## Same, and print the plan/state of every run
	terraform test -verbose

test-plan: ## Only the plan-time unit tests
	terraform test -filter=tests/plan.tftest.hcl

step: ## Reproduce one real error, e.g. make step STEP=01-empty-mock
	@test -n "$(STEP)" || { ls -d examples/mock-steps/*/ | xargs -n1 basename; exit 1; }
	terraform test -test-directory=examples/mock-steps/$(STEP)

naive: ## terraform plan with the real provider and no credentials (fails)
	cd examples/naive-provider && terraform init -input=false >/dev/null && terraform plan

naive-test: ## terraform test WITHOUT mock_provider (fails the same way)
	cd examples/naive-provider && terraform init -input=false >/dev/null && terraform test

clean: ## Remove the .terraform folders
	rm -rf .terraform examples/naive-provider/.terraform
