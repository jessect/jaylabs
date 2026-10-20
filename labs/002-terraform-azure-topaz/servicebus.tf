resource "azurerm_servicebus_namespace" "this" {
  name                = "sb-${var.project}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "orders" {
  name                                 = "orders"
  namespace_id                         = azurerm_servicebus_namespace.this.id
  max_delivery_count                   = 5
  dead_lettering_on_message_expiration = true
}
