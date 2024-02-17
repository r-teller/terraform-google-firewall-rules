output "firewall_rules_raw" {
  value = google_compute_firewall.firewall_rule.*
}

output "firewall_rules_json" {
  value = [for key in keys(local.firewall_rules) : {
    name    = local.firewall_rules[key].name != local.defaults_firewall_rule.name ? local.firewall_rules[key].name : key
    project = local.firewall_rules[key].project_id
    network = local.firewall_rules[key].network

    direction = local.firewall_rules[key].rule_direction
    disabled  = local.firewall_rules[key].disabled
    priority  = local.firewall_rules[key].priority

    description = try(local.firewall_rules[key].description, null)

    source_ranges      = local.firewall_rules[key].source_ranges
    destination_ranges = local.firewall_rules[key].target_ranges

    source_tags             = length(local.firewall_rules[key].source_tags) > 0 && local.firewall_rules[key].rule_direction == "INGRESS" ? local.firewall_rules[key].source_tags : null
    source_service_accounts = length(local.firewall_rules[key].source_service_accounts) > 0 && local.firewall_rules[key].rule_direction == "INGRESS" ? local.firewall_rules[key].source_service_accounts : null
    target_tags             = length(local.firewall_rules[key].target_tags) > 0 && local.firewall_rules[key].rule_direction == "INGRESS" ? local.firewall_rules[key].target_tags : length(local.firewall_rules[key].source_tags) > 0 && local.firewall_rules[key].rule_direction == "EGRESS" ? local.firewall_rules[key].source_tags : null
    target_service_accounts = length(local.firewall_rules[key].target_service_accounts) > 0 && local.firewall_rules[key].rule_direction == "INGRESS" ? local.firewall_rules[key].target_service_accounts : length(local.firewall_rules[key].source_service_accounts) > 0 && local.firewall_rules[key].rule_direction == "EGRESS" ? local.firewall_rules[key].source_service_accounts : null

    rules = {
      allow = [for rule in local.firewall_rules[key].rules : rule if local.firewall_rules[key].rule_action == "allow"]
      deny  = [for rule in local.firewall_rules[key].rules : rule if local.firewall_rules[key].rule_action == "deny"]
    }
  }]
}
