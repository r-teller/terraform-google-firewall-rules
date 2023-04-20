# output "firewall_rule" {
#   value = google_compute_firewall.firewall_rule
# }

# output "firewall" {
#   value = {
#     direction               = local.rule_direction
#     description             = lookup(var.firewall_rule, "description", null)
#     source_ranges           = length(local.source_ranges) > 0 && local.rule_direction == "INGRESS" ? local.source_ranges : length(local.source_ranges) == 0 && local.rule_direction == "INGRESS" ? [] : null
#     destination_ranges      = length(local.target_ranges) > 0 && local.rule_direction == "EGRESS" ? local.target_ranges : length(local.target_ranges) == 0 && local.rule_direction == "EGRESS" ? [] : null
#     disabled                = lookup(var.firewall_rule, "disabled", false)
#     priority                = lookup(var.firewall_rule, "priority", 1000)
#     source_tags             = length(local.source_tags) > 0 && local.rule_direction == "INGRESS" ? local.source_tags : null
#     source_service_accounts = length(local.source_service_accounts) > 0 && local.rule_direction == "INGRESS" ? local.source_service_accounts : null
#     target_tags             = length(local.target_tags) > 0 && local.rule_direction == "INGRESS" ? local.target_tags : length(local.source_tags) > 0 && local.rule_direction == "EGRESS" ? local.source_tags : null
#     target_service_accounts = length(local.target_service_accounts) > 0 && local.rule_direction == "INGRESS" ? local.target_service_accounts : length(local.source_service_accounts) > 0 && local.rule_direction == "EGRESS" ? local.source_service_accounts : null
#   }
# }

# output "firewall_rules_json" {
#   value = [for key in keys(local.firewall_rules) : {
#     name    = local.firewall_rules[key].name != local.defaults_firewall_rule.name ? local.firewall_rules[key].name : key
#     project = local.firewall_rules[key].project_id
#     network = local.firewall_rules[key].network

#     direction = local.firewall_rules[key].rule_direction
#     disabled  = local.firewall_rules[key].disabled
#     priority  = local.firewall_rules[key].priority

#     description        = try(local.firewall_rules[key].description, null)
#     source_ranges      = length(local.firewall_rules[key].source_ranges) > 0 && local.firewall_rules[key].rule_direction == "INGRESS" ? local.firewall_rules[key].source_ranges : length(local.firewall_rules[key].source_ranges) == 0 && local.firewall_rules[key].rule_direction == "INGRESS" ? [] : null
#     destination_ranges = length(local.firewall_rules[key].target_ranges) > 0 && local.firewall_rules[key].rule_direction == "EGRESS" ? local.firewall_rules[key].target_ranges : length(local.firewall_rules[key].target_ranges) == 0 && local.firewall_rules[key].rule_direction == "EGRESS" ? [] : null

#     source_tags             = length(local.firewall_rules[key].source_tags) > 0 && local.firewall_rules[key].rule_direction == "INGRESS" ? local.firewall_rules[key].source_tags : null
#     source_service_accounts = length(local.firewall_rules[key].source_service_accounts) > 0 && local.firewall_rules[key].rule_direction == "INGRESS" ? local.firewall_rules[key].source_service_accounts : null
#     target_tags             = length(local.firewall_rules[key].target_tags) > 0 && local.firewall_rules[key].rule_direction == "INGRESS" ? local.firewall_rules[key].target_tags : length(local.firewall_rules[key].source_tags) > 0 && local.firewall_rules[key].rule_direction == "EGRESS" ? local.firewall_rules[key].source_tags : null
#     target_service_accounts = length(local.firewall_rules[key].target_service_accounts) > 0 && local.firewall_rules[key].rule_direction == "INGRESS" ? local.firewall_rules[key].target_service_accounts : length(local.firewall_rules[key].source_service_accounts) > 0 && local.firewall_rules[key].rule_direction == "EGRESS" ? local.firewall_rules[key].source_service_accounts : null

#     rules = {
#       allow = [for rule in local.firewall_rules[key].rules : rule if local.firewall_rules[key].rule_action == "allow"]
#       deny  = [for rule in local.firewall_rules[key].rules : rule if local.firewall_rules[key].rule_action == "deny"]
#     }
#   }]
# }
