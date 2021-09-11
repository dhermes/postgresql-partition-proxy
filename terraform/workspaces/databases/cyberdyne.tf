module "cyberdyne_database" {
  source = "../../modules/postgresql-database"

  db_name        = "cyberdyne"
  admin_password = "ijkl9012"
  app_password   = "9012ijkl"

  providers = {
    postgresql = postgresql.cyberdyne
  }
}

module "cyberdyne_grants" {
  source = "../../modules/postgresql-grants"

  schema     = module.cyberdyne_database.db_name
  db_name    = module.cyberdyne_database.db_name
  admin_role = module.cyberdyne_database.admin_role
  app_role   = module.cyberdyne_database.app_role

  providers = {
    postgresql = postgresql.cyberdyne
  }
}
