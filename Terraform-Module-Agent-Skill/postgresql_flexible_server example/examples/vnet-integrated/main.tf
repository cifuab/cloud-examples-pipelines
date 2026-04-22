provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

# Networking prerequisites — VNet with a dedicated delegated subnet for PostgreSQL.
resource "azurerm_virtual_network" "example" {
  name                = "vnet-example-dev-uksouth-001"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "postgres" {
  name                 = "snet-postgres-dev-uksouth-001"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "postgres-flexible-server"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Private DNS zone for server name resolution within the VNet.
# The zone name must end with .postgres.database.azure.com.
resource "azurerm_private_dns_zone" "postgres" {
  name                = "example-dev.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "vnet-link-postgres-dev"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.example.id
  resource_group_name   = azurerm_resource_group.example.name
}

module "postgresql" {
  source = "../../"

  name                = "psql-example-dev-uksouth-001"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  postgresql_version    = "16"
  sku_name              = "GP_Standard_D2s_v3"
  storage_mb            = 65536
  backup_retention_days = 14

  delegated_subnet_id = azurerm_subnet.postgres.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  high_availability = {
    mode = "ZoneRedundant"
  }

  maintenance_window = {
    day_of_week  = 0 # Sunday
    start_hour   = 2
    start_minute = 0
  }

  administrator_login    = "psqladmin"
  administrator_password = var.administrator_password

  databases = {
    appdb = {}
  }

  server_configurations = {
    "max_connections" = "200"
  }

  tags = {
    environment = "dev"
    project     = "example"
    owner       = "platform-team"
    cost-center = "CC-00000"
  }

  # Ensure the DNS zone VNet link is in place before the server is created.
  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}
