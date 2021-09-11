resource "postgresql_schema" "application" {
  name     = var.schema
  owner    = var.admin_role
  database = var.db_name
}

resource "postgresql_grant" "grant_application_schema_to_admin" {
  role        = var.admin_role
  database    = var.db_name
  schema      = postgresql_schema.application.name
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

resource "postgresql_grant" "grant_application_schema_to_app" {
  role        = var.app_role
  database    = var.db_name
  schema      = postgresql_schema.application.name
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "app_table_grant" {
  database    = var.db_name
  role        = var.app_role
  schema      = postgresql_schema.application.name
  object_type = "table"
  privileges  = ["SELECT", "DELETE", "INSERT", "UPDATE"]
}

resource "postgresql_grant" "app_seq_grant" {
  database    = var.db_name
  role        = var.app_role
  schema      = postgresql_schema.application.name
  object_type = "sequence"
  privileges  = ["SELECT", "UPDATE"]
}

resource "postgresql_default_privileges" "app_table_grant" {
  database    = var.db_name
  role        = var.app_role
  schema      = postgresql_schema.application.name
  owner       = var.admin_role
  object_type = "table"
  privileges  = ["SELECT", "DELETE", "INSERT", "UPDATE"]
}

resource "postgresql_default_privileges" "app_seq_grant" {
  database    = var.db_name
  role        = var.app_role
  schema      = postgresql_schema.application.name
  owner       = var.admin_role
  object_type = "sequence"
  privileges  = ["SELECT", "UPDATE"]
}
