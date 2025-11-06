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

  validation {
    condition = alltrue([
      for rule in var.firewall_rules : (
        # Get all CIDRs from both sources and targets
        length([
          for item in concat(rule.sources, rule.targets) : item
          if can(cidrsubnet(item, 0, 0))
        ]) == 0 ? true : ( # No CIDRs, skip validation
          # Check if all CIDRs are the same IP version (all have :: or none have ::)
          alltrue([
            for item in concat(rule.sources, rule.targets) : strcontains(item, "::")
            if can(cidrsubnet(item, 0, 0))
          ]) || alltrue([
            for item in concat(rule.sources, rule.targets) : !strcontains(item, "::")
            if can(cidrsubnet(item, 0, 0))
          ])
        )
      )
    ])
    error_message = "Cannot mix IPv4 and IPv6 CIDRs in the same firewall rule. GCP firewall rules are single-stack only - each rule must use either IPv4 or IPv6 addresses, not both. Create separate rules for each IP version."
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

variable "implicit_ip_version" {
  description = "Default IP version to use for implicit addresses when sources or destinations contain only tags or service accounts (no CIDRs to infer from). The module will always try to infer the IP version from existing CIDRs first before using this default. Only applies when include_implicit_addresses is true. GCP firewall rules are single-stack only (either IPv4 or IPv6, not both)."
  type        = string
  default     = "IPV4"

  validation {
    condition = contains([
      "IPV4",
      "IPV6"
    ], var.implicit_ip_version)
    error_message = "implicit_ip_version must be 'IPV4' or 'IPV6'. The module automatically infers IP version from existing CIDRs when possible."
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
