module "veneer" {
  source = "../../modules/postgresql-database"

  db_name        = "veneer"
  admin_password = "abcd1234"
  app_password   = "1234abcd"

  providers = {
    postgresql = postgresql.veneer
  }
}

resource "postgresql_extension" "veneer_postgres_fdw" {
  provider = postgresql.veneer

  name     = "postgres_fdw"
  schema   = "public"
  database = module.veneer.db_name
}

resource "postgresql_grant" "grant_fdw_admin" {
  provider = postgresql.veneer

  role        = module.veneer.admin_role
  database    = module.veneer.db_name
  schema      = "public"
  object_type = "foreign_data_wrapper"
  objects     = [postgresql_extension.veneer_postgres_fdw.name]
  privileges  = ["USAGE"]
}
