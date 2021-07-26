locals {
    rule_action = lower(var.firewall_rule.action)
    rule_direction = upper(lookup(var.firewall_rule, "direction", "ingress"))

    source_service_accounts = [ for x in var.firewall_rule.sources: x if length(split("@",x)) > 1 && !can(cidrnetmask(x)) ]
    source_tags             = [ for x in var.firewall_rule.sources: x if length(split("@",x)) < 2 && !can(cidrnetmask(x)) ]
    _source_ranges          = [ for x in var.firewall_rule.sources: x if can(cidrnetmask(x)) ]
    source_ranges           = length(concat(local.source_service_accounts,local.source_tags,local._source_ranges)) > 0 ? local._source_ranges : ["0.0.0.0/0"]

    target_service_accounts = [ for x in var.firewall_rule.targets: x if length(split("@",x)) > 1 && !can(cidrnetmask(x)) ]
    target_tags             = [ for x in var.firewall_rule.targets: x if length(split("@",x)) < 2 && !can(cidrnetmask(x)) ]
    _target_ranges          = [ for x in var.firewall_rule.targets: x if can(cidrnetmask(x)) ]
    target_ranges           = length( concat(local.target_service_accounts,local.target_tags,local._target_ranges)) > 0 ? local._target_ranges : ["0.0.0.0/0"]
}

resource "google_compute_firewall" "firewall_rule" {
    name    = "${var.firewall_rule.fileName}--${var.firewall_rule.id}"
    project = var.project_id
    network = var.network

    direction               = local.rule_direction
    description             = lookup(var.firewall_rule, "description",null)
    source_ranges           = length(local.source_ranges) > 0 && local.rule_direction == "INGRESS" ? local.source_ranges : length(local.source_ranges) == 0 && local.rule_direction == "INGRESS" ? [] : null
    destination_ranges      = length(local.target_ranges) > 0 && local.rule_direction == "EGRESS" ? local.target_ranges : length(local.target_ranges) == 0 && local.rule_direction == "EGRESS" ? [] : null
    disabled                = lookup(var.firewall_rule, "disabled", false)
    priority                = lookup(var.firewall_rule, "priority", 1000)
    source_tags             = length(local.source_tags) > 0 && local.rule_direction == "INGRESS" ?  local.source_tags : null
    source_service_accounts = length(local.source_service_accounts) > 0 && local.rule_direction == "INGRESS" ? local.source_service_accounts : null
    target_tags             = length(local.target_tags) > 0 && local.rule_direction == "INGRESS" ? local.target_tags : length(local.source_tags) > 0 && local.rule_direction == "EGRESS" ? local.source_tags : null
    target_service_accounts = length(local.target_service_accounts) > 0 && local.rule_direction == "INGRESS" ? local.target_service_accounts : length(local.source_service_accounts) > 0 && local.rule_direction == "EGRESS" ? local.source_service_accounts : null      

    dynamic "log_config" {
        for_each = can(var.firewall_rule.log_config) && upper(var.firewall_rule.log_config) != "DISABLED" ? [1] : []
        content {
            metadata = var.firewall_rule.log_config
        }
    }

    dynamic "allow" {
        for_each = [for rule in var.firewall_rule.rules : rule if local.rule_action == "allow"]
            iterator = rule
            content {
                protocol = rule.value.protocol
                ports    = rule.value.ports
            }
    }
    dynamic "deny" {
        for_each = [for rule in var.firewall_rule.rules : rule if local.rule_action == "deny"]
            iterator = rule
            content {
                protocol = rule.value.protocol
                ports    = rule.value.ports
            }
    }
}