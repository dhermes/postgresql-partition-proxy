resource "postgresql_role" "user" {
  name                = var.username
  password            = var.password # WARNING!! This is very bad to do
  login               = true
  encrypted_password  = true
  skip_reassign_owned = true
}
