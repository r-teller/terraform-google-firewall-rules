variable "network" {
  description = "Name of the network this set of firewall rules applies to."
  default     = null
}

variable "project_id" {
  description = "Project id of the project that holds the network."
  default     = null
}

variable "firewall_rules" {
  description = "Firewall rule that need to be created"
}

variable "prefix" {
  default = null
}

variable "environment" {
  default = null
}
