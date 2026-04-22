output "id" {
  description = "Resource ID of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.id
}

output "name" {
  description = "Name of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.name
}

output "fqdn" {
  description = "Fully qualified domain name (FQDN) of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "principal_id" {
  description = "Principal ID of the system-assigned managed identity. Use this to grant the server access to other Azure resources (e.g. Key Vault for customer-managed keys)."
  value       = azurerm_postgresql_flexible_server.this.identity[0].principal_id
}

output "database_ids" {
  description = "Map of database names to their resource IDs for all databases created by this module."
  value       = { for k, v in azurerm_postgresql_flexible_server_database.this : k => v.id }
}
