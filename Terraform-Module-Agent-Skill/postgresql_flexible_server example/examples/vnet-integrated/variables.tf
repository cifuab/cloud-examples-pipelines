variable "resource_group_name" {
  description = "Name of the resource group to create for this example."
  type        = string
  default     = "rg-psql-vnet-example-001"
}

variable "location" {
  description = "Azure region to deploy into. Must support Availability Zones for ZoneRedundant HA."
  type        = string
  default     = "uksouth"
}

variable "administrator_password" {
  description = "Administrator password for the PostgreSQL server. Source from a secret store — do not hardcode."
  type        = string
  sensitive   = true
}
