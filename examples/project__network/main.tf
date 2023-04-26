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

  firewall_rules = local.firewall_rules
}

# ### Creates JSON file that contains a list of all configured rules
# resource "local_file" "rules_json" {
#   content  = jsonencode(module.firewall_rules.firewall_rules_raw)
#   filename = "${path.module}/outputs/managed.json"
# }
