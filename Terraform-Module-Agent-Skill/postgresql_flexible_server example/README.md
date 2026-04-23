# terraform-azurerm-postgresql-flexible-server

> Provisions a standard Azure PostgreSQL Flexible Server with consistent naming, tagging, high availability, VNet integration, configurable authentication, and optional initial database and server parameter configuration.

## Purpose

This module encapsulates a reusable platform pattern for deploying Azure PostgreSQL Flexible Server consistently across workloads. It handles:

- Server provisioning with sensible production defaults (GP SKU, 32 GiB storage, auto-grow, 7-day backup)
- VNet integration via delegated subnet and private DNS zone (no public access when VNet-integrated)
- High availability configuration (SameZone or ZoneRedundant)
- Authentication via password, Azure Entra ID (Active Directory), or both
- System-assigned managed identity (always enabled)
- Optional initial database creation (with `prevent_destroy` to guard against data loss)
- Optional server configuration parameter overrides
- Diagnostic log and metric forwarding to a Log Analytics workspace
- Consistent tagging with `managed-by = terraform` always applied

## Module boundary

- **Owns:** `azurerm_postgresql_flexible_server`, `azurerm_postgresql_flexible_server_database` (optional), `azurerm_postgresql_flexible_server_configuration` (optional), `azurerm_monitor_diagnostic_setting` (optional)
- **Expects from consumers:** pre-created resource group; pre-created delegated subnet and private DNS zone with VNet link (if using VNet integration); Log Analytics workspace ID (if diagnostics enabled)
- **Does not own:** resource groups, virtual networks, subnets, subnet delegations, private DNS zones, DNS zone VNet links, Log Analytics workspaces

## Usage example

```hcl
module "postgresql" {
  source = "git::https://github.com/your-org/terraform-modules.git//terraform-azurerm-postgresql-flexible-server?ref=v1.0.0"

  name                = "psql-myapp-prod-uksouth-001"
  resource_group_name = "rg-myapp-prod-uksouth-001"
  location            = "uksouth"

  postgresql_version    = "16"
  sku_name              = "GP_Standard_D2s_v3"
  storage_mb            = 65536
  backup_retention_days = 14

  delegated_subnet_id = azurerm_subnet.postgres.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  high_availability = {
    mode = "ZoneRedundant"
  }

  administrator_login    = "psqladmin"
  administrator_password = var.db_admin_password  # source from Key Vault, never hardcode

  databases = {
    appdb = {}
  }

  diagnostic_settings = {
    enabled                    = true
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  tags = {
    environment = "prod"
    project     = "myapp"
    owner       = "platform-team"
    cost-center = "CC-12345"
  }
}
```

## Assumptions and trade-offs

- System-assigned managed identity is always enabled. This is the foundation for keyless access to other Azure services (e.g. Key Vault for customer-managed keys) and follows the principle of least privilege.
- `public_network_access_enabled` is forced to `false` when `delegated_subnet_id` is set. VNet-integrated servers must not be publicly reachable.
- Zone and HA standby zone changes are ignored via `lifecycle.ignore_changes`. This prevents Terraform from forcing a failback after a high availability failover event, which would cause unnecessary downtime.
- Databases are protected with `lifecycle { prevent_destroy = true }`. To drop a database, first remove the `prevent_destroy` block from the module source, then apply.
- `administrator_password` must be sourced from Azure Key Vault or a Terraform secret input. Never commit passwords to source control or hardcode in `.tfvars` files.
- Storage can only be scaled up. Reducing `storage_mb` forces a new server to be created.

## Generating the inputs/outputs table

After any change to variables or outputs, regenerate the README table:

```bash
terraform-docs .
```

If using pre-commit hooks, add the following to `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/terraform-docs/terraform-docs
    rev: "v0.19.0"
    hooks:
      - id: terraform-docs-go
        args: ["--config", ".terraform-docs.yml", "."]
```

<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-postgresql-flexible-server

Provisions a standard Azure PostgreSQL Flexible Server with consistent naming, tagging,
high availability, VNet integration, configurable authentication, and optional initial
database and server parameter configuration.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.69.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_postgresql_flexible_server.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server_configuration.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_database.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_database) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | Azure region in which to deploy the server (e.g. 'uksouth', 'westeurope'). | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the PostgreSQL Flexible Server. Must be globally unique, 3–63 characters, start and end with a lowercase letter or digit, and contain only lowercase letters, numbers, and hyphens. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group in which to create the PostgreSQL Flexible Server. | `string` | n/a | yes |
| <a name="input_administrator_login"></a> [administrator\_login](#input\_administrator\_login) | Administrator username for the server. Required when authentication.password\_auth\_enabled is true. Changing this forces a new resource to be created. | `string` | `"psqladmin"` | no |
| <a name="input_administrator_password"></a> [administrator\_password](#input\_administrator\_password) | Administrator password for the server. Required when authentication.password\_auth\_enabled is true. Source this from a secret store such as Azure Key Vault — never hardcode. | `string` | `null` | no |
| <a name="input_authentication"></a> [authentication](#input\_authentication) | Authentication configuration. Supports password authentication and/or Azure Entra ID (Active Directory) authentication. At least one must be enabled. | <pre>object({<br/>    active_directory_auth_enabled = optional(bool, false)<br/>    password_auth_enabled         = optional(bool, true)<br/>    tenant_id                     = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_auto_grow_enabled"></a> [auto\_grow\_enabled](#input\_auto\_grow\_enabled) | Whether storage auto-grow is enabled. Defaults to true. | `bool` | `true` | no |
| <a name="input_backup_retention_days"></a> [backup\_retention\_days](#input\_backup\_retention\_days) | Number of days to retain backups. Must be between 7 and 35. | `number` | `7` | no |
| <a name="input_databases"></a> [databases](#input\_databases) | Map of databases to create on the server. The map key is the database name. Databases are created with prevent\_destroy to guard against accidental data loss. | <pre>map(object({<br/>    charset   = optional(string, "UTF8")<br/>    collation = optional(string, "en_US.utf8")<br/>  }))</pre> | `{}` | no |
| <a name="input_delegated_subnet_id"></a> [delegated\_subnet\_id](#input\_delegated\_subnet\_id) | Resource ID of the subnet delegated to Microsoft.DBforPostgreSQL/flexibleServers. Required for VNet integration. When set, private\_dns\_zone\_id must also be provided and public network access is forced to false. | `string` | `null` | no |
| <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings) | Diagnostic settings to forward server logs and metrics to a Log Analytics workspace. log\_analytics\_workspace\_id is required when enabled is true. | <pre>object({<br/>    enabled                    = optional(bool, false)<br/>    log_analytics_workspace_id = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_geo_redundant_backup_enabled"></a> [geo\_redundant\_backup\_enabled](#input\_geo\_redundant\_backup\_enabled) | Whether geo-redundant backup is enabled. Enabling this forces a new resource to be created. Backup storage must be in the same region as the server for geo-redundant backup. | `bool` | `false` | no |
| <a name="input_high_availability"></a> [high\_availability](#input\_high\_availability) | High availability configuration. When set, a standby replica is provisioned for automatic failover. mode must be 'SameZone' or 'ZoneRedundant'. ZoneRedundant requires a region that supports Availability Zones. | <pre>object({<br/>    mode                      = string<br/>    standby_availability_zone = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Maintenance window configuration. All times are UTC. day\_of\_week: 0 (Sunday) to 6 (Saturday). When null, the system-managed maintenance window is used. | <pre>object({<br/>    day_of_week  = optional(number, 0)<br/>    start_hour   = optional(number, 0)<br/>    start_minute = optional(number, 0)<br/>  })</pre> | `null` | no |
| <a name="input_postgresql_version"></a> [postgresql\_version](#input\_postgresql\_version) | PostgreSQL major version. Valid values: 11, 12, 13, 14, 15, 16, 17, 18. | `string` | `"16"` | no |
| <a name="input_private_dns_zone_id"></a> [private\_dns\_zone\_id](#input\_private\_dns\_zone\_id) | Resource ID of the private DNS zone used for VNet-integrated server name resolution. The zone name must end with .postgres.database.azure.com. Required when delegated\_subnet\_id is set. | `string` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether public network access is enabled. Defaults to false. Forced to false when delegated\_subnet\_id is set. | `bool` | `false` | no |
| <a name="input_server_configurations"></a> [server\_configurations](#input\_server\_configurations) | Map of server configuration parameters to apply. Key is the configuration name (e.g. 'max\_connections'), value is the string value to set. | `map(string)` | `{}` | no |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | SKU name for the server. Format: {tier}\_Standard\_{size}. Tiers: B (Burstable), GP (General Purpose), MO (Memory Optimised). Examples: B\_Standard\_B1ms, GP\_Standard\_D2s\_v3, MO\_Standard\_E4s\_v3. | `string` | `"GP_Standard_D2s_v3"` | no |
| <a name="input_storage_mb"></a> [storage\_mb](#input\_storage\_mb) | Maximum storage allocated in MB. Valid values: 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216, 33553408. Storage can only be scaled up. | `number` | `32768` | no |
| <a name="input_storage_tier"></a> [storage\_tier](#input\_storage\_tier) | Storage performance tier (IOPS). Valid values: P4, P6, P10, P15, P20, P30, P40, P50, P60, P70, P80. When null, defaults to the appropriate tier for the chosen storage\_mb. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources created by this module. The 'managed-by = terraform' tag is always merged in. | `map(string)` | `{}` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | Availability Zone in which to place the primary server (e.g. '1', '2', '3'). When null, Azure assigns a zone automatically. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_database_ids"></a> [database\_ids](#output\_database\_ids) | Map of database names to their resource IDs for all databases created by this module. |
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | Fully qualified domain name (FQDN) of the PostgreSQL Flexible Server. |
| <a name="output_id"></a> [id](#output\_id) | Resource ID of the PostgreSQL Flexible Server. |
| <a name="output_name"></a> [name](#output\_name) | Name of the PostgreSQL Flexible Server. |
| <a name="output_principal_id"></a> [principal\_id](#output\_principal\_id) | Principal ID of the system-assigned managed identity. Use this to grant the server access to other Azure resources (e.g. Key Vault for customer-managed keys). |
<!-- END_TF_DOCS -->
