terraform {
  required_version = "= 1.0.6"

  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "= 1.14.0"
    }
  }
}
