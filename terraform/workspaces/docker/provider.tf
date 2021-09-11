provider "docker" {
  alias = "local"
  host  = "unix:///var/run/docker.sock"
}
