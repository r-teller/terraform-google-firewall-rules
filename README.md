# Google Cloud VPC Firewall Rules
This module that provides a simplified approach for creating/managing firewall rules in GCP. 

It supports mixed values in both the source and target JSON field and uses string matching to determine type, types and logic listed below....
-  service_accounts = `if length(split("@", x)) > 1`
-  tags             = `if length(split("@", x)) < 2 && !can(cidrnetmask(x))`
-  subnet_ranges    = `if can(cidrnetmask(x))`

## Example Json Firewall Rule
Firewall Rules must be formated as valid JSON and added to a directory called `rules`. The `id` field must be unique within a given JSON file but does not need to be globaly unique.

```json
[
    {
        "id": "1111111",
        "description": "This rule will allow all traffic from service-account-name@project-id.iam.gserviceaccount.com to 192.168.13.0/32 and instances running with service-account service-account-name@project-id.iam.gserviceaccount.com ",
        "action": "allow",
        "direction": "EGRESS",
        "log_config": "EXCLUDE_ALL_METADATA",
        "priority": 1000,
        "sources": [
            "service-account-name@project-id.iam.gserviceaccount.com"
        ],
        "targets": [
            "192.168.13.0/32",
            "service-account-name@project-id.iam.gserviceaccount.com"
        ],
        "rules": [
            {
                "protocol": "TCP",
                "ports": ["80","8080-8088"]
            }
        ]
    }
]
```

## Usage
Basic usage of this module is as follows:

```hcl
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

    project_id      = var.project_id
    network         = var.network

    for_each        = { for rule in local.firewall_rules:  "${rule.fileName}--${rule.id}" => rule }
    firewall_rule  = each.value
}
```

## Module Inputs
| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| project_id | Project id of the project that holds the network. | `string` | yes |
| network | Name of the network this set of firewall rules applies to. | `string` | yes |
| firewall_rule | Firewall Rule object to be passed to the Firewall Rules Module | `object` | yes |

### Firewall Rule Object Format
| Name | Description | Type | Default | Example | Required |
|------|-------------|------|---------|---------|:--------:|
| id | unique identifier for this rule within the json file | `String` | N/A | `uniqueid111` | yes |
| description | Description of what the rule is intended to do | `String` | `null` | `Description of firewall rule` | no |
| action | The action for the firewall rule | `ENUM(`<br>&emsp;`allow,`<br>&emsp;`deny`<br>`)` | N/A | `allow` | yes |
| direction | The direction for the firewall rule | `ENUM(`<br>&emsp;`INGRESS,`<br>&emsp;`EGRESS`<br>`)` | N/A | `INGRESS` | yes |
| log_config | This field denotes whether logging is enabled and if to include or exclude metadata for firewall logs. | `ENUM(`<br>&emsp;`EXCLUDE_ALL_METADATA,`<br>&emsp;`INCLUDE_ALL_METADATA,`<br>&emsp;`DISABLED`<br>`)` | `DISABLED` | `INCLUDE_ALL_METADATA` | no |
| priority | This field denotes whether to include or exclude metadata for firewall logs. | `Number` | `1000` | `1000` | no |
| disabled | Denotes whether the firewall rule is disabled, i.e not applied to the network it is associated with. | `Boolean` | `false` | `false` | no |
| sources | A list of instance tags, service accounts or subnet ranges indicating source resources that may make network connections | `list(String)` | N/A | `[]` | yes |
| targets | A list of instance tags, service accounts or subnet ranges indicating target resources that may recieve network connections | `list(String)` | N/A | `[]` | yes |
| rules | A list of protocols and optional list of ports to which this rule applies. Each ports entry must be either an integer or a range. | `list(Object{`<br>&emsp;`protocol=String,`<br>&emsp;`ports=list(String)`<br>`})` | N/A | `[{protocol=TCP,ports=[80,443]}]` | yes |

## Bonus Example
Using the local_file resource you can output the created rules to a JSON file and then use the provided PowerShell script to compare Firewall Rules managed by this Terraform Module and any existing rules in GCP to identify any unmanaged rules.

*Note:* This section expects an `ouputs` directory to exist as a valid target for JSON files

```hcl
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

    project_id      = var.project_id
    network         = var.network

    for_each        = { for rule in local.firewall_rules:  "${rule.fileName}--${rule.id}" => rule }
    firewall_rule  = each.value
}

### Creates JSON file that contains a list of all configured rules
resource "local_file" "rules_json" {
    content     = jsonencode((values(module.firewall_rules)).*.firewall_rule)
    filename = "${path.module}/outputs/managed.json"
}
```

```powershell
pwsh .\unmanaged_rules.ps1

project                network                        unmanaged firewall rule      disabled
-------                -------                        -----------------------      --------
rteller-demo-host-aaaa bridged-vpc-ic-remote-vpc-5b78 bridged-vpc-icr-echo-fw-5b78    False
rteller-demo-host-aaaa bridged-vpc-ic-remote-vpc-5b78 bridged-vpc-icr-iap-fw-5b78     False
```