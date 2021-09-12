module "bluth_co_grants" {
  source = "../../modules/postgresql-grants"

  schema     = "bluth_co"
  db_name    = module.shard1_database.db_name
  admin_role = module.shard1_database.admin_role
  app_role   = module.shard1_database.app_role

  providers = {
    postgresql = postgresql.shard1
  }
}
