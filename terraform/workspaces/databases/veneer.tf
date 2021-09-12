module "veneer_database" {
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
  database = module.veneer_database.db_name
}

resource "postgresql_grant" "grant_fdw_admin" {
  provider = postgresql.veneer

  role        = module.veneer_database.admin_role
  database    = module.veneer_database.db_name
  schema      = "public"
  object_type = "foreign_data_wrapper"
  objects     = [postgresql_extension.veneer_postgres_fdw.name]
  privileges  = ["USAGE"]
}

module "veneer_bluth_co_grants" {
  source = "../../modules/postgresql-grants"

  schema     = "bluth_co"
  db_name    = module.veneer_database.db_name
  admin_role = module.veneer_database.admin_role
  app_role   = module.veneer_database.app_role

  providers = {
    postgresql = postgresql.veneer
  }
}

module "veneer_cyberdyne_grants" {
  source = "../../modules/postgresql-grants"

  schema     = "cyberdyne"
  db_name    = module.veneer_database.db_name
  admin_role = module.veneer_database.admin_role
  app_role   = module.veneer_database.app_role

  providers = {
    postgresql = postgresql.veneer
  }
}

module "veneer_dunder_mifflin_grants" {
  source = "../../modules/postgresql-grants"

  schema     = "dunder_mifflin"
  db_name    = module.veneer_database.db_name
  admin_role = module.veneer_database.admin_role
  app_role   = module.veneer_database.app_role

  providers = {
    postgresql = postgresql.veneer
  }
}

module "veneer_initech_grants" {
  source = "../../modules/postgresql-grants"

  schema     = "initech"
  db_name    = module.veneer_database.db_name
  admin_role = module.veneer_database.admin_role
  app_role   = module.veneer_database.app_role

  providers = {
    postgresql = postgresql.veneer
  }
}
