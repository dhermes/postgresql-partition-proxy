module "cyberdyne_grants" {
  source = "../../modules/postgresql-grants"

  schema     = module.shard2_database.db_name
  db_name    = module.shard2_database.db_name
  admin_role = module.shard2_database.admin_role
  app_role   = module.shard2_database.app_role

  providers = {
    postgresql = postgresql.shard2
  }
}
