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
    source = "../../modules/firewall_rules"

    project_id      = var.project_id
    network         = var.network

    for_each        = { for rule in local.firewall_rules:  "${rule.fileName}--${rule.id}" => rule }
    firewall_rules  = each.value
}