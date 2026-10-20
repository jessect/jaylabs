# Unit tests: `command = plan` with a mocked azurerm provider.
# No Azure account, no credentials, no network. Runs in a few seconds.

mock_provider "azurerm" {
  source = "./tests/mocks"
}

run "names_follow_convention" {
  command = plan

  assert {
    condition     = azurerm_resource_group.this.name == "rg-jaylabs-dev"
    error_message = "resource group name must be rg-<project>-<environment>"
  }

  assert {
    condition     = azurerm_storage_account.this.name == "stjaylabsdev"
    error_message = "storage account name must be st<project><environment>"
  }

  assert {
    condition     = can(regex("^[a-z0-9]{3,24}$", azurerm_storage_account.this.name))
    error_message = "storage account name must be 3-24 lowercase letters or digits"
  }

  assert {
    condition     = azurerm_key_vault.this.name == "kv-jaylabs-dev" && length(azurerm_key_vault.this.name) <= 24
    error_message = "key vault name must be kv-<project>-<environment> and at most 24 characters"
  }

  assert {
    condition     = azurerm_linux_web_app.this.name == "app-jaylabs-dev"
    error_message = "web app name must be app-<project>-<environment>"
  }
}

run "mandatory_tags_win" {
  command = plan

  variables {
    tags = {
      owner      = "jay"
      managed_by = "clickops" # must be overwritten
    }
  }

  assert {
    condition = alltrue([
      for t in [
        azurerm_resource_group.this.tags,
        azurerm_storage_account.this.tags,
        azurerm_virtual_network.this.tags,
        azurerm_network_security_group.app.tags,
        azurerm_service_plan.this.tags,
        azurerm_linux_web_app.this.tags,
        azurerm_key_vault.this.tags,
      ] : t.managed_by == "terraform" && t.environment == "dev" && t.project == "jaylabs"
    ])
    error_message = "every taggable resource needs project, environment and managed_by = terraform"
  }

  assert {
    condition     = azurerm_resource_group.this.tags.owner == "jay"
    error_message = "extra tags must be kept"
  }
}

run "storage_is_hardened" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.min_tls_version == "TLS1_2"
    error_message = "storage must require TLS 1.2"
  }

  assert {
    condition     = azurerm_storage_account.this.https_traffic_only_enabled && !azurerm_storage_account.this.allow_nested_items_to_be_public
    error_message = "storage must be HTTPS-only and never allow public blobs"
  }

  assert {
    condition     = azurerm_storage_container.uploads.container_access_type == "private"
    error_message = "the uploads container must be private"
  }

  assert {
    condition     = azurerm_storage_account.this.account_replication_type == "LRS"
    error_message = "dev should use cheap LRS replication"
  }
}

run "nsg_only_opens_https" {
  command = plan

  variables {
    allowed_https_cidrs = ["203.0.113.0/24"]
  }

  # No inbound Allow rule may expose SSH (22) or RDP (3389).
  assert {
    condition = length([
      for r in azurerm_network_security_group.app.security_rule : r
      if r.direction == "Inbound" && r.access == "Allow" && contains(["22", "3389", "*"], r.destination_port_range)
    ]) == 0
    error_message = "the NSG must not allow SSH, RDP or all ports inbound"
  }

  assert {
    condition = anytrue([
      for r in azurerm_network_security_group.app.security_rule :
      r.name == "allow-https-in" && r.destination_port_range == "443" && r.source_address_prefixes == toset(["203.0.113.0/24"])
    ])
    error_message = "HTTPS must be allowed only from allowed_https_cidrs"
  }

  assert {
    condition = anytrue([
      for r in azurerm_network_security_group.app.security_rule :
      r.name == "deny-all-in" && r.priority == 4096 && r.access == "Deny"
    ])
    error_message = "the NSG needs an explicit deny-all-in rule at priority 4096"
  }

  assert {
    condition     = azurerm_subnet.app.address_prefixes[0] == "10.20.1.0/24"
    error_message = "the app subnet must be the second /24 of the VNet"
  }
}

run "web_app_is_locked_down" {
  command = plan

  assert {
    condition     = azurerm_linux_web_app.this.https_only
    error_message = "the web app must be HTTPS-only"
  }

  assert {
    condition     = azurerm_linux_web_app.this.site_config[0].minimum_tls_version == "1.2" && azurerm_linux_web_app.this.site_config[0].ftps_state == "Disabled"
    error_message = "the web app must require TLS 1.2 and disable FTP"
  }

  assert {
    condition     = azurerm_linux_web_app.this.identity[0].type == "SystemAssigned"
    error_message = "the web app needs a managed identity to read Key Vault"
  }
}

run "prod_is_stricter" {
  command = plan

  variables {
    environment     = "prod"
    app_service_sku = "P0v3"
  }

  assert {
    condition     = azurerm_storage_account.this.account_replication_type == "GRS"
    error_message = "prod storage must be geo-redundant (GRS)"
  }

  assert {
    condition     = azurerm_key_vault.this.purge_protection_enabled
    error_message = "prod key vault must have purge protection"
  }

  assert {
    condition     = azurerm_resource_group.this.name == "rg-jaylabs-prod"
    error_message = "prod resource group name is wrong"
  }
}
