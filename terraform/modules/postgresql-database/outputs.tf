output "admin_role" {
  value = module.admin_role.role_name
}

output "app_role" {
  value = module.app_role.role_name
}

output "db_name" {
  value = postgresql_database.db.name
}
