# Google Cloud VPC Firewall Rules
This module that provides a simplified approach for creating/managing firewall rules in GCP. 

It supports mixed values in both the source and target JSON field and uses string matching to determine type, types and logic listed below....
-  service_accounts = `if length(split("@", x)) > 1`
-  tags             = `if length(split("@", x)) < 2 && !can(cidrnetmask(x))`
-  subnet_ranges    = `if can(cidrnetmask(x))`

## Example Json Firewall Rule
Firewall Rules must be formated as valid JSON and added to a directory called `rules`. The `id` field is used to help uniquely identify the firewall rule within a specified environment,prefix,project when potential collisions could occur.

```json
[
    {
        "id": "fffb",
        "description": "This rule will allow IAP ranges access to all VMs on all ports.",
        "action": "allow",
        "direction": "ingress",
        "log_config": "EXCLUDE_ALL_METADATA",
        "priority": 65530,
        "sources": [
            "35.235.240.0/20"
        ],
        "targets": [ ],
        "rules": [
            {
                "protocol": "TCP",
                "ports": []
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
```

## Module Inputs
| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| project_id | Project id of the project that holds the network. | `string` | no |
| network | Name of the network this set of firewall rules applies to. | `string` | no |
| prefix | This field denotes the prefix tag for firewall rule, used for dynamic name generation. | `string` | no |
| environment | This field denotes the environment tag for firewall rule, used for dynamic name generation. | `string` | no |
| firewall_rules | Firewall Rule object to be passed to the Firewall Rules Module | `object` | yes |
*Note:* `project_id`, `network`, `prefix` & `environment` can be overloaded within the firewall_rules object
*Note:* `project_id`, `network` **MUST** be specified either as a var or within the `firewall_rules` object

### Firewall Rules Object Format
*Note:* Any field flagged below for `UUID Generation` will be used to generate a unique firewall rule name if the name field is not explicitly specified. This helps to prevent naming collisions in GCP and terraform state

| Name | Description | Type | UUID Generation | Default | Required |
|------|-------------|------|---------|---------|:--------:|
| name | This field denotes the explicit name of the firewall rule | `String` | &check; | N/A | no |
| project_id | This field denotes the explicit project_id of the firewall rule | `String` | &check; | N/A | no |
| network | This field denotes the explicit vpc of the firewall rule | `String` | &check; | N/A | no |
| environment | This field denotes the environment tag for firewall rule, used for dynamic name generation | `String` | &check; | N/A | no |
| prefix | This field denotes the prefix tag for firewall rule, used for dynamic name generation | `String` | &check; | N/A | no |
| id | This field denotes an identifier for this rule within the json file, used for dynamic name generation | `String` | &check; | N/A | no |
| description | Description of what the rule is intended to do | `String` | | `null` | no |
| action | The action for the firewall rule | `allow` or `deny` | | N/A | yes |
| direction | The direction for the firewall rule | `INGRESS` or `EGRESS` | | `INGRESS` | no |
| log_config | This field denotes whether logging is enabled and if to include or exclude metadata for firewall logs. | `EXCLUDE_ALL_METADATA`, `INCLUDE_ALL_METADATA` or `DISABLED` | | `DISABLED` | no |
| priority | This field denotes whether to include or exclude metadata for firewall logs. | `Number` | | `1000` | no |
| disabled | Denotes whether the firewall rule is disabled, i.e not applied to the network it is associated with. | `Boolean` | | `false` | no |
| sources | A list of instance tags, service accounts or subnet ranges indicating source resources that may initiate network connections | `list(String)` | | N/A | yes |
| targets | A list of instance tags, service accounts or subnet ranges indicating target resources that may recieve network connections | `list(String)` | | N/A |  yes |
| rules | A list of protocols and optional list of ports to which this rule applies. Each ports entry must be either an integer, range or an empty list `[]` to indicate all ports for the given protocol. | `list(Object{protocol=String, ports=list(Number), ports=list(String)})`  | | N/A | yes |

## Bonus Example
Using the local_file resource you can output the created rules to a JSON file and then use the provided PowerShell script to compare Firewall Rules managed by this Terraform Module and any existing rules in GCP to identify any unmanaged rules.

*Note:* This section expects an `ouputs` directory to exist as a valid target for JSON file output

```hcl
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
resource "local_file" "rules_json" {
  content  = jsonencode(module.firewall_rules.firewall_rules_raw)
  filename = "${path.module}/outputs/managed.json"
}
```

```powershell
## PowerShell example
pwsh .\unmanaged_rules.ps1

project                network                        unmanaged firewall rule      disabled
-------                -------                        -----------------------      --------
rteller-demo-host-aaaa bridged-vpc-ic-remote-vpc-5b78 bridged-vpc-icr-echo-fw-5b78    False
rteller-demo-host-aaaa bridged-vpc-ic-remote-vpc-5b78 bridged-vpc-icr-iap-fw-5b78     False
```