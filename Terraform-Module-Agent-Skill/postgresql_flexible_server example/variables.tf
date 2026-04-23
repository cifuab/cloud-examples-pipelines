# --- Required ---

variable "name" {
  description = "Name of the PostgreSQL Flexible Server. Must be globally unique, 3–63 characters, start and end with a lowercase letter or digit, and contain only lowercase letters, numbers, and hyphens."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "name must be 3–63 characters, start and end with a lowercase letter or digit, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the PostgreSQL Flexible Server."
  type        = string
}

variable "location" {
  description = "Azure region in which to deploy the server (e.g. 'uksouth', 'westeurope')."
  type        = string
}

# --- PostgreSQL version ---

variable "postgresql_version" {
  description = "PostgreSQL major version. Valid values: 11, 12, 13, 14, 15, 16, 17, 18."
  type        = string
  default     = "16"

  validation {
    condition     = contains(["11", "12", "13", "14", "15", "16", "17", "18"], var.postgresql_version)
    error_message = "postgresql_version must be one of: 11, 12, 13, 14, 15, 16, 17, 18."
  }
}

# --- Compute / SKU ---

variable "sku_name" {
  description = "SKU name for the server. Format: {tier}_Standard_{size}. Tiers: B (Burstable), GP (General Purpose), MO (Memory Optimised). Examples: B_Standard_B1ms, GP_Standard_D2s_v3, MO_Standard_E4s_v3."
  type        = string
  default     = "GP_Standard_D2s_v3"
}

# --- Storage ---

variable "storage_mb" {
  description = "Maximum storage allocated in MB. Valid values: 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216, 33553408. Storage can only be scaled up."
  type        = number
  default     = 32768

  validation {
    condition     = contains([32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216, 33553408], var.storage_mb)
    error_message = "storage_mb must be one of: 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216, 33553408."
  }
}

variable "storage_tier" {
  description = "Storage performance tier (IOPS). Valid values: P4, P6, P10, P15, P20, P30, P40, P50, P60, P70, P80. When null, defaults to the appropriate tier for the chosen storage_mb."
  type        = string
  default     = null

  validation {
    condition     = var.storage_tier == null || contains(["P4", "P6", "P10", "P15", "P20", "P30", "P40", "P50", "P60", "P70", "P80"], var.storage_tier)
    error_message = "storage_tier must be one of: P4, P6, P10, P15, P20, P30, P40, P50, P60, P70, P80."
  }
}

variable "auto_grow_enabled" {
  description = "Whether storage auto-grow is enabled. Defaults to true."
  type        = bool
  default     = true
}

# --- Backup ---

variable "backup_retention_days" {
  description = "Number of days to retain backups. Must be between 7 and 35."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 7 and 35."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "Whether geo-redundant backup is enabled. Enabling this forces a new resource to be created. Backup storage must be in the same region as the server for geo-redundant backup."
  type        = bool
  default     = false
}

# --- Networking ---

variable "delegated_subnet_id" {
  description = "Resource ID of the subnet delegated to Microsoft.DBforPostgreSQL/flexibleServers. Required for VNet integration. When set, private_dns_zone_id must also be provided and public network access is forced to false."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Resource ID of the private DNS zone used for VNet-integrated server name resolution. The zone name must end with .postgres.database.azure.com. Required when delegated_subnet_id is set."
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled. Defaults to false. Forced to false when delegated_subnet_id is set."
  type        = bool
  default     = false
}

# --- Availability Zone ---

variable "zone" {
  description = "Availability Zone in which to place the primary server (e.g. '1', '2', '3'). When null, Azure assigns a zone automatically."
  type        = string
  default     = null
}

# --- Authentication ---

variable "administrator_login" {
  description = "Administrator username for the server. Required when authentication.password_auth_enabled is true. Changing this forces a new resource to be created."
  type        = string
  default     = "psqladmin"
}

variable "administrator_password" {
  description = "Administrator password for the server. Required when authentication.password_auth_enabled is true. Source this from a secret store such as Azure Key Vault — never hardcode."
  type        = string
  default     = null
  sensitive   = true
}

variable "authentication" {
  description = "Authentication configuration. Supports password authentication and/or Azure Entra ID (Active Directory) authentication. At least one must be enabled."
  type = object({
    active_directory_auth_enabled = optional(bool, false)
    password_auth_enabled         = optional(bool, true)
    tenant_id                     = optional(string)
  })
  default = {}
}

# --- High Availability ---

variable "high_availability" {
  description = "High availability configuration. When set, a standby replica is provisioned for automatic failover. mode must be 'SameZone' or 'ZoneRedundant'. ZoneRedundant requires a region that supports Availability Zones."
  type = object({
    mode                      = string
    standby_availability_zone = optional(string)
  })
  default = null

  validation {
    condition     = var.high_availability == null || contains(["SameZone", "ZoneRedundant"], var.high_availability.mode)
    error_message = "high_availability.mode must be 'SameZone' or 'ZoneRedundant'."
  }
}

# --- Maintenance Window ---

variable "maintenance_window" {
  description = "Maintenance window configuration. All times are UTC. day_of_week: 0 (Sunday) to 6 (Saturday). When null, the system-managed maintenance window is used."
  type = object({
    day_of_week  = optional(number, 0)
    start_hour   = optional(number, 0)
    start_minute = optional(number, 0)
  })
  default = null
}

# --- Databases ---

variable "databases" {
  description = "Map of databases to create on the server. The map key is the database name. Databases are created with prevent_destroy to guard against accidental data loss."
  type = map(object({
    charset   = optional(string, "UTF8")
    collation = optional(string, "en_US.utf8")
  }))
  default = {}
}

# --- Server Configuration ---

variable "server_configurations" {
  description = "Map of server configuration parameters to apply. Key is the configuration name (e.g. 'max_connections'), value is the string value to set."
  type        = map(string)
  default     = {}
}

# --- Diagnostics ---

variable "diagnostic_settings" {
  description = "Diagnostic settings to forward server logs and metrics to a Log Analytics workspace. log_analytics_workspace_id is required when enabled is true."
  type = object({
    enabled                    = optional(bool, false)
    log_analytics_workspace_id = optional(string)
  })
  default = {}

  validation {
    condition     = !var.diagnostic_settings.enabled || var.diagnostic_settings.log_analytics_workspace_id != null
    error_message = "diagnostic_settings.log_analytics_workspace_id must be provided when diagnostic_settings.enabled is true."
  }
}

# --- Tags ---

variable "tags" {
  description = "Map of tags to apply to all resources created by this module. The 'managed-by = terraform' tag is always merged in."
  type        = map(string)
  default     = {}
}
