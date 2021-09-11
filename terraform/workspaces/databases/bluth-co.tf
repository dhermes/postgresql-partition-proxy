module "bluth_co_database" {
  source = "../../modules/postgresql-database"

  db_name        = "bluth_co"
  admin_password = "efgh5678"
  app_password   = "5678efgh"

  providers = {
    postgresql = postgresql.bluth_co
  }
}

module "bluth_co_grants" {
  source = "../../modules/postgresql-grants"

  schema     = module.bluth_co_database.db_name
  db_name    = module.bluth_co_database.db_name
  admin_role = module.bluth_co_database.admin_role
  app_role   = module.bluth_co_database.app_role

  providers = {
    postgresql = postgresql.bluth_co
  }
}
