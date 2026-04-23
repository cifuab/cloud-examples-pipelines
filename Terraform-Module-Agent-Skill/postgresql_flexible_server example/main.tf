/**
 * # terraform-azurerm-postgresql-flexible-server
 *
 * Provisions a standard Azure PostgreSQL Flexible Server with consistent naming, tagging,
 * high availability, VNet integration, configurable authentication, and optional initial
 * database and server parameter configuration.
 */

resource "azurerm_postgresql_flexible_server" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.postgresql_version

  administrator_login    = var.authentication.password_auth_enabled ? var.administrator_login : null
  administrator_password = var.authentication.password_auth_enabled ? var.administrator_password : null

  sku_name          = var.sku_name
  storage_mb        = var.storage_mb
  storage_tier      = var.storage_tier
  auto_grow_enabled = var.auto_grow_enabled

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  public_network_access_enabled = local.public_network_access_enabled

  zone = var.zone

  identity {
    type = "SystemAssigned"
  }

  dynamic "authentication" {
    for_each = [var.authentication]
    content {
      active_directory_auth_enabled = authentication.value.active_directory_auth_enabled
      password_auth_enabled         = authentication.value.password_auth_enabled
      tenant_id                     = authentication.value.tenant_id
    }
  }

  dynamic "high_availability" {
    for_each = var.high_availability != null ? [var.high_availability] : []
    content {
      mode                      = high_availability.value.mode
      standby_availability_zone = high_availability.value.standby_availability_zone
    }
  }

  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = maintenance_window.value.start_minute
    }
  }

  tags = local.tags

  lifecycle {
    # After a failover event, Azure updates zone and standby_availability_zone to reflect
    # the new primary. Ignoring these prevents Terraform from forcing a failback on the
    # next plan, which would cause unnecessary downtime.
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone,
    ]

    precondition {
      condition     = var.delegated_subnet_id == null || var.private_dns_zone_id != null
      error_message = "private_dns_zone_id must be provided when delegated_subnet_id is set."
    }

    precondition {
      condition     = !var.authentication.active_directory_auth_enabled || var.authentication.tenant_id != null
      error_message = "authentication.tenant_id must be provided when authentication.active_directory_auth_enabled is true."
    }

    precondition {
      condition     = !var.authentication.password_auth_enabled || var.administrator_password != null
      error_message = "administrator_password must be provided when authentication.password_auth_enabled is true."
    }
  }
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  for_each = var.databases

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.this.id
  collation = each.value.collation
  charset   = each.value.charset

  lifecycle {
    # Prevent accidental deletion of databases. To remove a database, first remove
    # prevent_destroy from this block, then run terraform apply.
    prevent_destroy = true
  }
}

resource "azurerm_postgresql_flexible_server_configuration" "this" {
  for_each = var.server_configurations

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = each.value
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.diagnostic_settings.enabled ? 1 : 0

  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_postgresql_flexible_server.this.id
  log_analytics_workspace_id = var.diagnostic_settings.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
