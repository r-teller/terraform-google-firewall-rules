locals {
  firewall_rule_path = "./rules"
  firewall_rule_sets = fileset(local.firewall_rule_path, "*.json")
  firewall_rules = flatten([for rules in local.firewall_rule_sets : [
    for rule in jsondecode(file("${local.firewall_rule_path}/${rules}")) :
    merge(rule, { fileName = split(".", rules)[0] })
    ]
  ])
}

module "firewall_rules" {
  source = "r-teller/firewall-rules/google"

  project_id = var.project_id
  network    = var.network

  for_each      = { for rule in local.firewall_rules : "${rule.fileName}--${rule.id}" => rule }
  firewall_rule = each.value
}

output "environment" {
  value = {
    network    = var.network,
    project_id = var.project_id,
  }
}

# ### Creates JSON file that contains a list of all configured rules
# resource "local_file" "rules_json" {
#   content  = jsonencode((values(module.firewall_rules)).*.firewall_rule)
#   filename = "${path.module}/outputs/managed.json"
# }