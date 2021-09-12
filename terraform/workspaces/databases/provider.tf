provider "postgresql" {
  alias     = "veneer"
  host      = "127.0.0.1"
  port      = 14797
  database  = "superuser_db"
  username  = "superuser"
  password  = "testpassword_superuser"
  sslmode   = "disable"
  superuser = false
}

provider "postgresql" {
  alias     = "shard1"
  host      = "127.0.0.1"
  port      = 29948
  database  = "superuser_db"
  username  = "superuser"
  password  = "testpassword_superuser"
  sslmode   = "disable"
  superuser = false
}

provider "postgresql" {
  alias     = "shard2"
  host      = "127.0.0.1"
  port      = 13366
  database  = "superuser_db"
  username  = "superuser"
  password  = "testpassword_superuser"
  sslmode   = "disable"
  superuser = false
}

provider "postgresql" {
  alias     = "shard3"
  host      = "127.0.0.1"
  port      = 11033
  database  = "superuser_db"
  username  = "superuser"
  password  = "testpassword_superuser"
  sslmode   = "disable"
  superuser = false
}
