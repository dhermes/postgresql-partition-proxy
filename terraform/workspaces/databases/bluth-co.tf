module "bluth_co_grants" {
  source = "../../modules/postgresql-grants"

  schema     = module.bluth_co_database.db_name
  db_name    = module.bluth_co_database.db_name
  admin_role = module.bluth_co_database.admin_role
  app_role   = module.bluth_co_database.app_role

  providers = {
    postgresql = postgresql.shard1
  }
}
