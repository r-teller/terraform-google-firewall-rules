locals {
  defaults_firewall_rule = {
    name        = "UNKNOWN",
    id          = "UNKNOWN",
    environment = "UNKNOWN",
    prefix      = "UNKNOWN",
    priority    = 1000,
    disabled    = false,
    direction   = "INGRESS",
    log_config  = "DISABLED",
  }

  _firewall_rules = [for firewall_rule in var.firewall_rules : {
    # name        = firewall_rule.name != null ? firewall_rule.name : local.defaults_firewall_rule.name
    name = coalesce(firewall_rule.name, local.defaults_firewall_rule.name)

    description = try(firewall_rule.description, firewall_rule.id, null)

    # id          = firewall_rule.id != null ? firewall_rule.id : local.defaults_firewall_rule.id
    id = coalesce(firewall_rule.id, local.defaults_firewall_rule.id)

    ## These are intended to be passed in to from the remote module to simplify tracking back to orginating JSON
    file_name  = firewall_rule.file_name
    rule_index = firewall_rule.rule_index

    # project_id = firewall_rule.project_id != null ? firewall_rule.project_id : var.project_id
    project_id = coalesce(firewall_rule.project_id, var.project_id)

    # network    = firewall_rule.network != null ? firewall_rule.network : var.network
    network = coalesce(firewall_rule.network, var.network)

    # prefix = (
    #   firewall_rule.prefix != null ? firewall_rule.prefix :
    #   var.prefix != null ? var.prefix : local.defaults_firewall_rule.prefix
    # )
    prefix = coalesce(firewall_rule.prefix, var.prefix, local.defaults_firewall_rule.prefix)

    # environment = (
    #   firewall_rule.environment != null ? firewall_rule.environment :
    #   var.environment != null ? var.environment : local.defaults_firewall_rule.environment
    # )
    environment = coalesce(firewall_rule.environment, var.environment, local.defaults_firewall_rule.environment)

    # priority    = try(firewall_rule.priority, local.defaults_firewall_rule.priority)
    priority    = coalesce(firewall_rule.priority, local.defaults_firewall_rule.priority)
    rule_action = lower(firewall_rule.action)

    rule_direction = upper(coalesce(firewall_rule.direction, local.defaults_firewall_rule.direction))
    disabled       = coalesce(firewall_rule.disabled, local.defaults_firewall_rule.disabled)

    source_service_accounts = [for x in firewall_rule.sources : trimspace(x) if length(split("@", trimspace(x))) > 1 && !can(cidrnetmask(trimspace(x)))]
    source_tags             = [for x in firewall_rule.sources : trimspace(x) if length(split("@", trimspace(x))) < 2 && !can(cidrnetmask(trimspace(x)))]
    source_cidrs            = [for x in firewall_rule.sources : trimspace(x) if can(cidrnetmask(trimspace(x)))]

    target_service_accounts = [for x in firewall_rule.targets : trimspace(x) if length(split("@", trimspace(x))) > 1 && !can(cidrnetmask(trimspace(x)))]
    target_tags             = [for x in firewall_rule.targets : trimspace(x) if length(split("@", trimspace(x))) < 2 && !can(cidrnetmask(trimspace(x)))]
    target_cidrs            = [for x in firewall_rule.targets : trimspace(x) if can(cidrnetmask(trimspace(x)))]


    log_config = coalesce(upper(firewall_rule.log_config), local.defaults_firewall_rule.log_config)
    rules      = try(firewall_rule.rules, null)
  }]

  firewall_rules_legacy = { for firewall_rule in local._firewall_rules : format("fw-r-%s",
    uuidv5("x500",
      format("PREFIX=%s,ENVIRONMENT=%s,PROJECT_ID=%s,NETWORK=%s,NAME=%s,ID=%s",
        firewall_rule.prefix,
        firewall_rule.environment,
        firewall_rule.project_id,
        firewall_rule.network,
        firewall_rule.name,
        firewall_rule.id,
      ))) => merge(firewall_rule, {
      source_ranges = length(concat(firewall_rule.source_service_accounts, firewall_rule.source_tags, firewall_rule.source_cidrs)) > 0 ? firewall_rule.source_cidrs : var.include_implicit_addresses ? ["0.0.0.0/0"] : []
      target_ranges = length(concat(firewall_rule.target_service_accounts, firewall_rule.target_tags, firewall_rule.target_cidrs)) > 0 ? firewall_rule.target_cidrs : var.include_implicit_addresses ? ["0.0.0.0/0"] : []
    })
  }

  firewall_rules = { for firewall_rule in local._firewall_rules : format("%s-%s%s",
    firewall_rule.prefix != "UNKNOWN" ? firewall_rule.prefix : "fw-r",
    firewall_rule.environment != "UNKNOWN" ? format("%s-", firewall_rule.environment) : "",
    uuidv5("x500", join(",", [for k2, v2 in {
      PREFIX      = var.override_dynamic_naming.include_prefix ? firewall_rule.prefix : null,
      ENVIRONMENT = var.override_dynamic_naming.include_environment ? firewall_rule.environment : null,
      PROJECT_ID  = var.override_dynamic_naming.include_project_id ? firewall_rule.project_id : null,
      NETWORK     = var.override_dynamic_naming.include_network ? firewall_rule.network : null,
      NAME        = var.override_dynamic_naming.include_name ? firewall_rule.name : null,
      ID          = var.override_dynamic_naming.include_id ? firewall_rule.id : null,
      } : format("%s=%s", k2, v2) if v2 != null]))) => merge(firewall_rule, {
      source_ranges = length(concat(firewall_rule.source_service_accounts, firewall_rule.source_tags, firewall_rule.source_cidrs)) > 0 ? firewall_rule.source_cidrs : var.include_implicit_addresses ? ["0.0.0.0/0"] : []
      target_ranges = length(concat(firewall_rule.target_service_accounts, firewall_rule.target_tags, firewall_rule.target_cidrs)) > 0 ? firewall_rule.target_cidrs : var.include_implicit_addresses ? ["0.0.0.0/0"] : []
    })
  }
}

resource "google_compute_firewall" "firewall_rule" {
  for_each = var.use_legacy_naming ? local.firewall_rules_legacy : local.firewall_rules
  name     = each.value.name != local.defaults_firewall_rule.name ? each.value.name : each.key
  project  = each.value.project_id
  network  = each.value.network

  direction = each.value.rule_direction
  disabled  = each.value.disabled
  priority  = each.value.priority

  description = try(each.value.description, null)

  source_ranges      = each.value.source_ranges
  destination_ranges = each.value.target_ranges

  source_tags             = length(each.value.source_tags) > 0 && each.value.rule_direction == "INGRESS" ? each.value.source_tags : null
  source_service_accounts = length(each.value.source_service_accounts) > 0 && each.value.rule_direction == "INGRESS" ? each.value.source_service_accounts : null

  target_tags             = length(each.value.target_tags) > 0 && each.value.rule_direction == "INGRESS" ? each.value.target_tags : length(each.value.source_tags) > 0 && each.value.rule_direction == "EGRESS" ? each.value.source_tags : null
  target_service_accounts = length(each.value.target_service_accounts) > 0 && each.value.rule_direction == "INGRESS" ? each.value.target_service_accounts : length(each.value.source_service_accounts) > 0 && each.value.rule_direction == "EGRESS" ? each.value.source_service_accounts : null


  dynamic "log_config" {
    for_each = each.value.log_config != "DISABLED" ? [1] : []
    content {
      metadata = each.value.log_config
    }
  }

  dynamic "allow" {
    for_each = [for rule in each.value.rules : rule if each.value.rule_action == "allow"]
    iterator = rule
    content {
      protocol = lower(rule.value.protocol)
      ports    = rule.value.ports != null ? rule.value.ports : []
    }
  }

  dynamic "deny" {
    for_each = [for rule in each.value.rules : rule if each.value.rule_action == "deny"]
    iterator = rule
    content {
      protocol = lower(rule.value.protocol)
      ports    = rule.value.ports != null ? rule.value.ports : []
    }
  }
}
