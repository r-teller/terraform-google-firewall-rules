locals {
    firewall_rule_path = "./rules"
    firewall_rule_sets = fileset(local.firewall_rule_path,"*")
    firewall_rules = flatten([ for rules in local.firewall_rule_sets: [
            for rule in jsondecode(file("${local.firewall_rule_path}/${rules}")): 
                merge(rule,{fileName=split(".",rules)[0]})
            ]    
    ])
}

module "firewall_rules" { 
    source  = "r-teller/firewall-rules/google"
    version = "0.1.0-alpha"


    project_id      = var.project_id
    network         = var.network

    for_each        = { for rule in local.firewall_rules:  "${rule.fileName}--${rule.id}" => rule }
    firewall_rule  = each.value
}



# module "firewall-rule" {
#   source  = "r-teller/firewall-rules/google"
#   version = "0.1.0-alpha"
#   # insert the 3 required variables here
# }

# module "http_getFirewallRules" {
#     source      = "../modules/get_firewall_rules"
#     project_id  = var.project_id
#     network     = var.network
# }

output "environment" {
    value = {
        network     = var.network,
        project_id  = var.project_id,
    }
}

resource "local_file" "rules_json" {
    content     = jsonencode((values(module.firewall_rules)).*.firewall_rule)
    filename = "${path.module}/outputs/managed.json"
}