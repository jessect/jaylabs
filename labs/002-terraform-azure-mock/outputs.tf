output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "web_app_url" {
  value = "https://${azurerm_linux_web_app.this.default_hostname}"
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "subnet_id" {
  value = azurerm_subnet.app.id
}
