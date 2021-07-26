output "firewall_rule" {
  value = google_compute_firewall.firewall_rule
}

output "firewall" {
  value = {
    direction               = local.rule_direction
    description             = lookup(var.firewall_rule, "description", null)
    source_ranges           = length(local.source_ranges) > 0 && local.rule_direction == "INGRESS" ? local.source_ranges : length(local.source_ranges) == 0 && local.rule_direction == "INGRESS" ? [] : null
    destination_ranges      = length(local.target_ranges) > 0 && local.rule_direction == "EGRESS" ? local.target_ranges : length(local.target_ranges) == 0 && local.rule_direction == "EGRESS" ? [] : null
    disabled                = lookup(var.firewall_rule, "disabled", false)
    priority                = lookup(var.firewall_rule, "priority", 1000)
    source_tags             = length(local.source_tags) > 0 && local.rule_direction == "INGRESS" ? local.source_tags : null
    source_service_accounts = length(local.source_service_accounts) > 0 && local.rule_direction == "INGRESS" ? local.source_service_accounts : null
    target_tags             = length(local.target_tags) > 0 && local.rule_direction == "INGRESS" ? local.target_tags : length(local.source_tags) > 0 && local.rule_direction == "EGRESS" ? local.source_tags : null
    target_service_accounts = length(local.target_service_accounts) > 0 && local.rule_direction == "INGRESS" ? local.target_service_accounts : length(local.source_service_accounts) > 0 && local.rule_direction == "EGRESS" ? local.source_service_accounts : null
  }
}