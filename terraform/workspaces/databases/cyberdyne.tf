module "cyberdyne_grants" {
  source = "../../modules/postgresql-grants"

  schema     = module.cyberdyne_database.db_name
  db_name    = module.cyberdyne_database.db_name
  admin_role = module.cyberdyne_database.admin_role
  app_role   = module.cyberdyne_database.app_role

  providers = {
    postgresql = postgresql.shard2
  }
}
