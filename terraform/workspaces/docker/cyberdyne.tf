module "cyberdyne" {
  source = "../../modules/postgres-container"

  port           = "13366"
  container_name = "dev-postgres-cyberdyne"
  network_name   = docker_network.ppp.name

  providers = {
    docker = docker.local
  }
}
