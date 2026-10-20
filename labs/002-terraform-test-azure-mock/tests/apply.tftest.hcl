# Apply-mode tests: Terraform "applies" against the mock provider, so computed
# attributes (ids, hostnames, principal ids) exist and we can test the wiring
# between resources and the outputs. Still no Azure, still $0.

mock_provider "azurerm" {
  source = "./tests/mocks"
}

# Values Azure would return. Fixed here so the asserts are deterministic.
override_resource {
  target = azurerm_linux_web_app.this
  values = {
    default_hostname = "app-jaylabs-dev.azurewebsites.net"
    # A nested block is overridden with an object, not a list: identity = { ... }
    identity = {
      principal_id = "11111111-1111-1111-1111-111111111111"
      tenant_id    = "00000000-0000-0000-0000-000000000001"
    }
  }
}

override_resource {
  target = azurerm_key_vault_secret.db_password
  values = {
    versionless_id = "https://kv-jaylabs-dev.vault.azure.net/secrets/db-password"
  }
}

run "full_stack_apply" {
  # command = apply is the default

  assert {
    condition     = output.web_app_url == "https://app-jaylabs-dev.azurewebsites.net"
    error_message = "web_app_url must be https:// + the web app default hostname, got ${output.web_app_url}"
  }

  assert {
    condition     = output.key_vault_uri == "https://kv-mock.vault.azure.net/"
    error_message = "key_vault_uri must come from the key vault"
  }

  assert {
    condition     = azurerm_subnet_network_security_group_association.app.subnet_id == azurerm_subnet.app.id
    error_message = "the NSG must be attached to the app subnet"
  }

  assert {
    condition     = azurerm_linux_web_app.this.virtual_network_subnet_id == azurerm_subnet.app.id
    error_message = "the web app must be integrated with the app subnet"
  }
}

run "app_identity_can_read_secrets" {
  assert {
    condition     = azurerm_role_assignment.app_secrets_user.principal_id == "11111111-1111-1111-1111-111111111111"
    error_message = "the Secrets User role must go to the web app's managed identity"
  }

  assert {
    condition     = azurerm_role_assignment.app_secrets_user.role_definition_name == "Key Vault Secrets User"
    error_message = "the web app must get read-only access to secrets"
  }

  assert {
    condition     = azurerm_role_assignment.deployer_secrets_officer.principal_id == "00000000-0000-0000-0000-000000000002"
    error_message = "the identity running Terraform needs Secrets Officer to write the secret"
  }

  assert {
    condition     = azurerm_linux_web_app.this.app_settings["DB_PASSWORD"] == "@Microsoft.KeyVault(SecretUri=https://kv-jaylabs-dev.vault.azure.net/secrets/db-password)"
    error_message = "DB_PASSWORD must be a Key Vault reference, never the secret value"
  }
}

run "secret_value_is_generated" {
  assert {
    condition     = length(random_password.db.result) == 24
    error_message = "the database password must be 24 characters"
  }

  assert {
    condition     = azurerm_key_vault_secret.db_password.value == random_password.db.result
    error_message = "the secret must store the generated password"
  }
}
