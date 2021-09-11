module "initech" {
  source = "../../modules/postgresql-container"

  port           = "11033"
  container_name = "dev-postgres-initech"
  network_name   = docker_network.ppp.name

  providers = {
    docker = docker.local
  }
}
