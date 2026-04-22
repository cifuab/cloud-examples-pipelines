output "server_id" {
  description = "Resource ID of the PostgreSQL Flexible Server."
  value       = module.postgresql.id
}

output "server_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL Flexible Server."
  value       = module.postgresql.fqdn
}

output "database_ids" {
  description = "Map of database names to their resource IDs."
  value       = module.postgresql.database_ids
}
