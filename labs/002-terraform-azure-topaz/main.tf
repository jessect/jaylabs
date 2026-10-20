locals {
  # Storage account names: 3-24 lowercase letters and digits, no dashes.
  storage_name = replace("st${var.project}", "-", "")
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.project}"
  location = var.location
}

resource "azurerm_storage_account" "this" {
  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_storage_queue" "orders" {
  name               = "orders"
  storage_account_id = azurerm_storage_account.this.id
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.project}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
