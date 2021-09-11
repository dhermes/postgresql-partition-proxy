resource "docker_network" "ppp" {
  name     = "dev-network-ppp"
  internal = true
}
