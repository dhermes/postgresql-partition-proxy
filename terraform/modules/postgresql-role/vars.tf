variable "username" {
  type        = string
  description = "The name of the role for a PostgreSQL user"
}

variable "password" {
  type        = string
  description = "The password to use for the newly created user"
}
