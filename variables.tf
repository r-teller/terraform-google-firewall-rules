variable "firewall_rules" {
  description = "Collection of firewall rules that need to be created"
  type = list(object({
    name        = optional(string),
    id          = optional(string),
    file_name   = optional(string, null),
    rule_index   = optional(string, null),
    description = optional(string, null),
    action      = string,
    direction   = optional(string, "INGRESS"),
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
    error_message = "firewall_rule ports must contain a list of ports or port-ranges."
  }

  validation {
    condition = length([
      for value in var.firewall_rules[*].action : true if contains([
        "allow",
        "deny"
      ], lower(value))
    ]) == length(var.firewall_rules)
    error_message = "firewall_rule action must be one of 'ALLOW' or 'DENY'."
  }
}

variable "project_id" {
  type        = string
  description = "Project id of the project that holds the network."
  default     = null
}

variable "network" {
  type        = string
  description = "Name of the network this set of firewall rules applies to."
  default     = null
}
variable "use_legacy_naming" {
  description = "Toggle to use legacy naming conventions for firewall rules."
  type        = bool
  default     = false
}

variable "include_implicit_addresses" {
  description = "When a source or destination specification is ommited from in an ingress or egress rule, Google Cloud uses the default source address ranges. This flag includes them as explicit configuration attributes based on the ip_version setting."
  type        = bool
  default     = true
}

variable "ip_version" {
  description = "IP version to use for implicit addresses when sources or destinations are not specified. AUTO (default) automatically detects the IP version based on specified CIDRs in the rule. IPV4 or IPV6 can be used to explicitly override auto-detection. GCP firewall rules are single-stack only (either IPv4 or IPv6, not both)."
  type        = string
  default     = "AUTO"

  validation {
    condition = contains([
      "AUTO",
      "IPV4",
      "IPV6"
    ], var.ip_version)
    error_message = "ip_version must be one of 'AUTO' (default), 'IPV4', or 'IPV6'. GCP does not support dual-stack firewall rules."
  }
}

variable "override_dynamic_naming" {
  description = "Configuration object for dynamic naming of firewall rules, specifying which attributes to include. These flags do not work with legacy naming"
  default = {
    include_prefix      = true,
    include_environment = true,
    include_project_id  = true,
    include_network     = true,
    include_name        = true,
    include_id          = true
  }
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
  description = "This field denotes the prefix tag for firewall rule, used for dynamic name generation."
  type        = string
  default     = null
}

variable "environment" {
  description = "This field denotes the environment tag for firewall rule, used for dynamic name generation."
  type        = string
  default     = null
}
