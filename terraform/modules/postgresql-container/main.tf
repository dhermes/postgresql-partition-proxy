data "docker_image" "postgres" {
  name = "postgres:13.3-alpine3.14"
}

resource "docker_container" "database" {
  attach   = false
  name     = var.container_name
  hostname = "127.0.0.1"
  ports {
    external = var.port
    internal = "5432"
  }
  env = [
    "POSTGRES_DB=superuser_db",
    "POSTGRES_USER=superuser",
    "POSTGRES_PASSWORD=testpassword_superuser",
    "POSTGRES_INITDB_ARGS=--auth-host=scram-sha-256 --auth-local=scram-sha-256",
  ]
  tmpfs = {
    "/var/lib/postgresql/data" = ""
  }
  volumes {
    host_path      = abspath("${path.module}/postgresql.conf")
    container_path = "/etc/postgresql/postgresql.conf"
  }
  volumes {
    host_path      = abspath("${path.module}/pg_hba.conf")
    container_path = "/etc/postgresql/pg_hba.conf"
  }
  command = [
    "-c", "config_file=/etc/postgresql/postgresql.conf",
    "-c", "hba_file=/etc/postgresql/pg_hba.conf",
  ]
  image = data.docker_image.postgres.name
}

# NOTE: It's crucial to use `docker network connect` vs. starting the container
#       with `docker run --network`. Since the network is `--internal`, any
#       use of `--publish` will be ignored if `--network` is also provided
#       to `docker run`.
resource "null_resource" "network_connect" {
  provisioner "local-exec" {
    command = "docker network connect ${var.network_name} ${docker_container.database.name} --alias ${docker_container.database.name}"
  }
}
