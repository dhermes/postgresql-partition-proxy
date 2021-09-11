module "veneer" {
  source = "../../modules/postgresql-container"

  port           = "14797"
  container_name = "dev-postgres-veneer"
  network_name   = docker_network.ppp.name

  providers = {
    docker = docker.local
  }
}
