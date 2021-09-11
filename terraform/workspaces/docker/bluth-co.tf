module "bluth_co" {
  source = "../../modules/postgres-container"

  port           = "29948"
  container_name = "dev-postgres-bluth-co"
  network_name   = docker_network.ppp.name

  providers = {
    docker = docker.local
  }
}
