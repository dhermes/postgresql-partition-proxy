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
  database = module.veneer.db_name
}
