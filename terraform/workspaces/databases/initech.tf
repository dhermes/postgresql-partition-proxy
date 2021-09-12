module "initech_grants" {
  source = "../../modules/postgresql-grants"

  schema     = "initech"
  db_name    = module.shard3_database.db_name
  admin_role = module.shard3_database.admin_role
  app_role   = module.shard3_database.app_role

  providers = {
    postgresql = postgresql.shard3
  }
}
