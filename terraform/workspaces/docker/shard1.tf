module "shard1" {
  source = "../../modules/postgresql-container"

  port           = "29948"
  container_name = "dev-postgres-shard1"
  network_name   = docker_network.ppp.name

  providers = {
    docker = docker.local
  }
}
