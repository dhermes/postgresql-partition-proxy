module "initech_database" {
  source = "../../modules/postgresql-database"

  db_name        = "initech"
  admin_password = "mnop3456"
  app_password   = "3456mnop"

  providers = {
    postgresql = postgresql.initech
  }
}

module "initech_grants" {
  source = "../../modules/postgresql-grants"

  schema     = module.initech_database.db_name
  db_name    = module.initech_database.db_name
  admin_role = module.initech_database.admin_role
  app_role   = module.initech_database.app_role

  providers = {
    postgresql = postgresql.initech
  }
}
