variable "schema" {
  type        = string
  description = "The name of the schema to be created"
}

variable "db_name" {
  type        = string
  description = "The name of the database"
}

variable "admin_role" {
  type        = string
  description = "The name of the admin PostgreSQL role for the DB"
}

variable "app_role" {
  type        = string
  description = "The name of the app PostgreSQL role for the DB"
}
