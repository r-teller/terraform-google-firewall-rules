locals {
    rule_action = lower(var.firewall_rules.action)
    rule_direction = upper(var.firewall_rules.direction)

    source_service_accounts = [ for x in var.firewall_rules.sources: x if length(split("@",x)) > 1 && !can(cidrnetmask(x)) ]
    source_tags = [ for x in var.firewall_rules.sources: x if length(split("@",x)) < 2 && !can(cidrnetmask(x)) ]
    source_ranges = [ for x in var.firewall_rules.sources: x if can(cidrnetmask(x)) ]

    target_service_accounts = [ for x in var.firewall_rules.targets: x if length(split("@",x)) > 1 && !can(cidrnetmask(x)) ]
    target_tags = [ for x in var.firewall_rules.targets: x if length(split("@",x)) < 2 && !can(cidrnetmask(x)) ]
    target_ranges = [ for x in var.firewall_rules.targets: x if can(cidrnetmask(x)) ]
}

resource "google_compute_firewall" "firewall_rules" {
    name    = "${var.firewall_rules.fileName}--${var.firewall_rules.id}"
    project = var.project_id
    network = var.network

    direction               = local.rule_direction
    description             = lookup(var.firewall_rules, "description",null)
    source_ranges           = length(local.source_ranges) > 0 && local.rule_direction == "INGRESS" ? local.source_ranges: null
    destination_ranges      = length(local.target_ranges) > 0 && local.rule_direction == "EGRESS" ? local.target_ranges : null
    disabled                = lookup(var.firewall_rules, "disabled", false)
    priority                = lookup(var.firewall_rules, "priority", 1000)
    source_tags             = length(local.source_tags) > 0 && local.rule_direction == "INGRESS" ?  local.source_tags : null
    source_service_accounts = length(local.source_service_accounts) > 0 && local.rule_direction == "INGRESS" ? local.source_service_accounts : null
    target_tags             = length(local.target_tags) > 0 && local.rule_direction == "INGRESS" ? local.target_tags : length(local.source_tags) > 0 && local.rule_direction == "EGRESS" ? local.source_tags : null
    target_service_accounts = length(local.target_service_accounts) > 0 && local.rule_direction == "INGRESS" ? local.target_service_accounts : length(local.source_service_accounts) > 0 && local.rule_direction == "EGRESS" ? local.source_service_accounts : null      

    dynamic "log_config" {
        for_each = can(var.firewall_rules.log_config) ? [1] : []
        content {
            metadata = var.firewall_rules.log_config
        }
    }

    dynamic "allow" {
        for_each = [for rule in var.firewall_rules.rules : rule if local.rule_action == "allow"]
            iterator = rule
            content {
                protocol = rule.value.protocol
                ports    = rule.value.ports
            }
    }
    dynamic "deny" {
        for_each = [for rule in var.firewall_rules.rules : rule if local.rule_action == "deny"]
            iterator = rule
            content {
                protocol = rule.value.protocol
                ports    = rule.value.ports
            }
    }
}


output "firewall" {
    value = {
        direction               = local.rule_direction
        description             = lookup(var.firewall_rules, "description",null)
        source_ranges           = length(local.source_ranges) > 0 && local.rule_direction == "INGRESS" ? local.source_ranges: null
        destination_ranges      = length(local.target_ranges) > 0 && local.rule_direction == "EGRESS" ? local.target_ranges : null
        disabled                = lookup(var.firewall_rules, "disabled", false)
        priority                = lookup(var.firewall_rules, "priority", 1000)
        source_tags             = length(local.source_tags) > 0 && local.rule_direction == "INGRESS" ?  local.source_tags : null
        source_service_accounts = length(local.source_service_accounts) > 0 && local.rule_direction == "INGRESS" ? local.source_service_accounts : null
        target_tags             = length(local.target_tags) > 0 && local.rule_direction == "INGRESS" ? local.target_tags : length(local.source_tags) > 0 && local.rule_direction == "EGRESS" ? local.source_tags : null
        target_service_accounts = length(local.target_service_accounts) > 0 && local.rule_direction == "INGRESS" ? local.target_service_accounts : length(local.source_service_accounts) > 0 && local.rule_direction == "EGRESS" ? local.source_service_accounts : null        
    }
}