output "server_id" {
  description = "Resource ID of the PostgreSQL Flexible Server."
  value       = module.postgresql.id
}

output "server_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL Flexible Server."
  value       = module.postgresql.fqdn
}

output "server_principal_id" {
  description = "Principal ID of the server's system-assigned managed identity."
  value       = module.postgresql.principal_id
}

output "database_ids" {
  description = "Map of database names to their resource IDs."
  value       = module.postgresql.database_ids
}
