variable "port" {
  type        = string
  description = "The port that will be exposed on the host for the container"
}

variable "container_name" {
  type        = string
  description = "The name of the container that will be created"
}

variable "network_name" {
  type        = string
  description = "The name of the network that the container will be attached to"
}
