module "dunder_mifflin_grants" {
  source = "../../modules/postgresql-grants"

  schema     = "dunder_mifflin"
  db_name    = module.shard2_database.db_name
  admin_role = module.shard2_database.admin_role
  app_role   = module.shard2_database.app_role

  providers = {
    postgresql = postgresql.shard2
  }
}
