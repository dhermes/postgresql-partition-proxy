module "admin_role" {
  source = "../postgresql-role"

  username = "${var.db_name}_admin"
  password = var.admin_password
}

resource "postgresql_database" "db" {
  name              = var.db_name
  owner             = module.admin_role.role_name
  template          = "template0"
  encoding          = "UTF8"
  lc_collate        = "en_US.UTF-8"
  lc_ctype          = "en_US.UTF-8"
  connection_limit  = -1
  allow_connections = true
}

module "app_role" {
  source = "../postgresql-role"

  username = "${var.db_name}_app"
  password = var.app_password
}

resource "postgresql_extension" "pgcrypto" {
  name     = "pgcrypto"
  schema   = "public"
  database = postgresql_database.db.name
}
