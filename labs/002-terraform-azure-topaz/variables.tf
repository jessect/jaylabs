variable "metadata_host" {
  description = "Where azurerm downloads the cloud endpoints from. Topaz serves them on port 8899."
  type        = string
  default     = "topaz.local.dev:8899"
}

variable "subscription_id" {
  description = "Subscription created by Topaz at start-up (docker-compose.yml)."
  type        = string
  default     = "00000000-0000-0000-0000-000000000001"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "project" {
  description = "Short name used in every resource name. Changing it also changes the hostnames in `make hosts`."
  type        = string
  default     = "jaylabs-lab002"
}
