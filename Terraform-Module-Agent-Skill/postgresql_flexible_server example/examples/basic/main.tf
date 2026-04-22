provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

# Minimal configuration: Burstable SKU, public access enabled (dev/test only).
# For production workloads, use the vnet-integrated example.
module "postgresql" {
  source = "../../"

  name                = "psql-example-dev-uksouth-001"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  postgresql_version = "16"
  sku_name           = "B_Standard_B1ms"
  storage_mb         = 32768

  administrator_login    = "psqladmin"
  administrator_password = var.administrator_password

  # Public access is required for this example as there is no VNet integration.
  # Do not use this in production.
  public_network_access_enabled = true

  databases = {
    appdb = {}
  }

  tags = {
    environment = "dev"
    project     = "example"
    owner       = "platform-team"
    cost-center = "CC-00000"
  }
}
