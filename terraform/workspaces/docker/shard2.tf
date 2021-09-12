module "shard2" {
  source = "../../modules/postgresql-container"

  port           = "13366"
  container_name = "dev-postgres-shard2"
  network_name   = docker_network.ppp.name

  providers = {
    docker = docker.local
  }
}
