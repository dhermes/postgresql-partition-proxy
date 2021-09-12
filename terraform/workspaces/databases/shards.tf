module "shard1_database" {
  source = "../../modules/postgresql-database"

  db_name        = "bookstore"
  admin_password = "efgh5678"
  app_password   = "5678efgh"

  providers = {
    postgresql = postgresql.shard1
  }
}

module "shard2_database" {
  source = "../../modules/postgresql-database"

  db_name        = "cyberdyne"
  admin_password = "ijkl9012"
  app_password   = "9012ijkl"

  providers = {
    postgresql = postgresql.shard2
  }
}

module "shard3_database" {
  source = "../../modules/postgresql-database"

  db_name        = "initech"
  admin_password = "mnop3456"
  app_password   = "3456mnop"

  providers = {
    postgresql = postgresql.shard3
  }
}
