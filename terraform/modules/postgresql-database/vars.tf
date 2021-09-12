variable "db_name" {
  type        = string
  description = "The name of the database to be created"
}

variable "admin_password" {
  type        = string
  description = "The password to use for the newly created admin user"
}

variable "app_password" {
  type        = string
  description = "The password to use for the newly created app user"
}
