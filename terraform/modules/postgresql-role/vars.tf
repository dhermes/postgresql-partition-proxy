variable "username" {
  type        = string
  description = "The name of the role for a PostgreSQL user"
}

variable "password" {
  type        = string
  description = "The password to use for the newly created user"
}

variable "search_path" {
  type        = list(string)
  default     = null
  description = "The (optional) search path to use for the created user"
}
