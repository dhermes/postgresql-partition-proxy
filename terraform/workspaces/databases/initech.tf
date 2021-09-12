module "initech_grants" {
  source = "../../modules/postgresql-grants"

  schema     = module.initech_database.db_name
  db_name    = module.initech_database.db_name
  admin_role = module.initech_database.admin_role
  app_role   = module.initech_database.app_role

  providers = {
    postgresql = postgresql.shard3
  }
}
