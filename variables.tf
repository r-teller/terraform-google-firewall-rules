variable "network" {
  description = "Name of the network this set of firewall rules applies to."
}

variable "project_id" {
  description = "Project id of the project that holds the network."
}

variable "firewall_rule" {
    description = "Firewall rule that need to be created"
}