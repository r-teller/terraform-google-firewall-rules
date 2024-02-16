variable "firewall_rules" {
  description = "Collection of firewall rules that need to be created"
  type = list(object({
    name        = optional(string),
    id          = optional(string),
    description = optional(string, null),
    action      = string,
    direction   = optional(string, "INGRESS")
    log_config  = optional(string, "DISABLED"),
    priority    = optional(number, 1000),
    disabled    = optional(bool, false),
    project_id  = optional(string),
    network     = optional(string),
    environment = optional(string),
    prefix      = optional(string),
    sources     = optional(list(string), []),
    targets     = optional(list(string), []),
    rules = list(object({
      protocol = string,
      ports    = optional(list(string))
    }))
  }))

  validation {
    condition = length([
      for value in var.firewall_rules[*].direction : true if contains([
        "INGRESS",
        "EGRESS"
      ], upper(value))
    ]) == length(var.firewall_rules)
    error_message = "firewall_rule direction must be one of 'INGRESS' or 'EGRESS'."
  }

  validation {
    condition = length([
      for value in var.firewall_rules[*].log_config : true if contains([
        "EXCLUDE_ALL_METADATA",
        "INCLUDE_ALL_METADATA",
        "DISABLED"
      ], upper(value))
    ]) == length(var.firewall_rules)
    error_message = "firewall_rule log_config must be one of 'EXCLUDE_ALL_METADATA', 'INCLUDE_ALL_METADATA' or 'DISABLED'."
  }

  validation {
    condition = alltrue([
      for value in flatten(var.firewall_rules[*].rules.*.ports) : (can(regex("^\\d+$", value)) || can(regex("^\\d+-\\d+$", value)))
    ])
    error_message = "firewall_rule ports must contain a list of numbers or number ranges"
  }

  validation {
    condition = length([
      for value in var.firewall_rules[*].action : true if contains([
        "allow",
        "deny"
      ], lower(value))
    ]) == length(var.firewall_rules)
    error_message = "firewall_rule log_config must be one of 'allow' or 'deny'."
  }
}

variable "project_id" {
  type = string
  description = "Project id of the project that holds the network."
  default     = null
}

variable "network" {
  type = string
  description = "Name of the network this set of firewall rules applies to."
  default     = null
}
variable "use_legacy_naming" {
  default = false
  type    = bool
}

variable "override_dynamic_naming" {
  default = {}
  type = object({
    include_prefix      = optional(bool, true)
    include_environment = optional(bool, true)
    include_project_id  = optional(bool, true)
    include_network     = optional(bool, true)
    include_name        = optional(bool, true)
    include_id          = optional(bool, true)
  })
}

variable "prefix" {
  type    = string
  default = null
}

variable "environment" {
  type    = string
  default = null
}
