# Google Cloud VPC Firewall Rules
This module that provides a simplified approach for creating/managing firewall rules in GCP leveraging JSON as the source of truth. 

It supports mixed values in both the source and target JSON field and uses string matching to determine type, with types and logic listed below....
-  service_accounts = `if length(split("@", x)) > 1`
-  tags             = `if length(split("@", x)) < 2 && !can(cidrnetmask(x))`
-  subnet_ranges    = `if can(cidrnetmask(x))`


## JSON Generator
https://r-teller.github.io/terraform-google-firewall-rules

## JSON Schema Documentation
https://r-teller.github.io/terraform-google-firewall-rules/documentation/

## Include Implicit Addresses

This module incorporates a feature to enhance clarity around the specification of source and destination addresses in firewall rules. By default, Google Cloud assumes the IPv4 address range of 0.0.0.0/0 (representing any IPv4 address) for any ingress rule without a specified source or any egress rule without a specified destination. To make this behavior explicit and enhance rule readability, this module automatically includes these default addresses as rule attributes.

### Configuring Implicit Address Inclusion

The inclusion of default IPv4 address ranges can be controlled using the include_implicit_addresses variable:

- **Enabled (default)**: The module will automatically add `0.0.0.0/0` to the rule attributes for unspecified sources in ingress rules and unspecified destinations in egress rules, making the default behavior explicit.
 - Disabled: By setting `var.include_implicit_addresses` to `false`, users can opt out of this automatic inclusion, allowing for the manual specification of sources and destinations as needed.

This functionality ensures that the module's behavior aligns with Google Cloud's default settings while offering users the option to customize how these defaults are represented in their firewall rule configurations.


## Combining Subnet Ranges with Service Accounts or Tags
When specifying firewall rules it is possible to combine subnet_ranges with either service_accounts or tags enhances the flexibility and granularity of your network's security configuration for both ingress and egress traffic. If subnet_ranges are used in conjunction with service_accounts or tags, the rule applies to traffic originating from the specified IP ranges or to instances associated with the specified service accounts or tags. This combination allows for specifying rules that target both broad network segments (via IP ranges) and specific sets of instances (via service accounts or tags), ensuring precise and effective control over access and traffic flow within your network.

- For Ingress Traffic: Rule matches if the source of the traffic is within the specified subnet_ranges or if it originates from instances identified by the specified service_accounts or tags.
- For Egress Traffic: Rule applies if the destination of the traffic is within the specified subnet_ranges or if it targets instances identified by the specified service_accounts or tags.

## Example Json Firewall Rule
Firewall Rules must be formatted as valid JSON and added to a directory called `rules`. The `id` field is used to help uniquely identify the firewall rule within a specified environment,prefix,project when potential collisions could occur.

```json
[
    {
        "id": "fffb",
        "description": "This rule will allow IAP ranges access to all VMs within 192.168.0.0/16 on all ports.",
        "action": "allow",
        "direction": "ingress",
        "log_config": "EXCLUDE_ALL_METADATA",
        "priority": 65530,
        "sources": [
            "35.235.240.0/20"
        ],
        "targets": [
          "192.168.0.0/16"
        ],
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

  # Optional field used to include implicit sources within Firewall rules
  include_implicit_addresses = true

  # Optional field for using legacy dynamic naming
  use_legacy_naming = false

  # Optional field that can be used to limit attributes used in dynamic naming
  override_dynamic_naming = {
    include_prefix      = true
    include_environment = true
    include_project_id  = true
    include_network     = true
    include_name        = true
    include_id          = true
  }  
}
```

## Updates and Enhancements
The dynamic naming for firewall rules has been updated to provide more flexibility in managing rules across different environments. The naming scheme can now exclude certain attributes based on your configuration needs. This feature is controlled by the `var.override_dynamic_naming` object, which allows for specifying which attributes to include or exclude in the firewall rule's dynamic name.

Additionally, the option to use legacy naming conventions has been added. This can be toggled with the `var.use_legacy_naming` variable, allowing users to choose between the new dynamic naming scheme or the previous static method based on UUID generation.

## Module Inputs
| Name                       | Description                                                                                        | Type     | Required |
| -------------------------- | -------------------------------------------------------------------------------------------------- | -------- | :------: |
| project_id                 | Project id of the project that holds the network.                                                  | `string` |    no    |
| network                    | Name of the network this set of firewall rules applies to.                                         | `string` |    no    |
| prefix                     | This field denotes the prefix tag for firewall rule, used for dynamic name generation.             | `string` |    no    |
| environment                | This field denotes the environment tag for firewall rule, used for dynamic name generation.        | `string` |    no    |
| firewall_rules             | Firewall Rule object to be passed to the Firewall Rules Module                                     | `object` |   yes    |
| include_implicit_addresses | Toggle to include implicit source or target addresses within firewall rules.                       | `bool`   |    no    |
| use_legacy_naming          | Toggle to use legacy naming conventions for firewall rules.                                        | `bool`   |    no    |
| override_dynamic_naming    | Configuration object for dynamic naming of firewall rules, specifying which attributes to include. | `object` |    no    |

>*Note:* 
>- `project_id`, `network`, `prefix` & `environment` can be overloaded within the firewall_rules object
>- `project_id`, `network` **MUST** be specified either as a variable or within the `firewall_rules` object
>- The `override_dynamic_naming` object allows for granular control over the dynamic naming process (done through UUID generation below), enabling users to include or exclude specific attributes from the firewall rule's name.

### Firewall Rules Object Format
>*Note:*  Any field flagged below for `UUID Generation` will be used to generate a unique firewall rule name if the name field is not explicitly specified. This helps to prevent naming collisions in GCP and terraform state

| Name        | Description                                                                                                                                                                                      | Type                                                                    | UUID Generation | Default    | Required |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------- | --------------- | ---------- | :------: |
| name        | This field denotes the explicit name of the firewall rule                                                                                                                                        | `String`                                                                | &check;         | N/A        |    no    |
| project_id  | This field denotes the explicit project_id of the firewall rule                                                                                                                                  | `String`                                                                | &check;         | N/A        |    no    |
| network     | This field denotes the explicit vpc of the firewall rule                                                                                                                                         | `String`                                                                | &check;         | N/A        |    no    |
| environment | This field denotes the environment tag for firewall rule, used for dynamic name generation                                                                                                       | `String`                                                                | &check;         | N/A        |    no    |
| prefix      | This field denotes the prefix tag for firewall rule, used for dynamic name generation                                                                                                            | `String`                                                                | &check;         | N/A        |    no    |
| id          | This field denotes an identifier for this rule within the json file, used for dynamic name generation                                                                                            | `String`                                                                | &check;         | N/A        |    no    |
| description | Description of what the rule is intended to do                                                                                                                                                   | `String`                                                                |                 | `null`     |    no    |
| action      | The action for the firewall rule                                                                                                                                                                 | `allow` or `deny`                                                       |                 | N/A        |   yes    |
| direction   | The direction for the firewall rule                                                                                                                                                              | `INGRESS` or `EGRESS`                                                   |                 | `INGRESS`  |    no    |
| log_config  | This field denotes whether logging is enabled and if to include or exclude metadata for firewall logs.                                                                                           | `EXCLUDE_ALL_METADATA`, `INCLUDE_ALL_METADATA` or `DISABLED`            |                 | `DISABLED` |    no    |
| priority    | This field denotes whether to include or exclude metadata for firewall logs.                                                                                                                     | `Number`                                                                |                 | `1000`     |    no    |
| disabled    | Denotes whether the firewall rule is disabled, i.e not applied to the network it is associated with.                                                                                             | `Boolean`                                                               |                 | `false`    |    no    |
| sources     | A list of instance tags, service accounts or subnet ranges indicating source resources that may initiate network connections                                                                     | `list(String)`                                                          |                 | N/A        |   yes    |
| targets     | A list of instance tags, service accounts or subnet ranges indicating target resources that may receive network connections                                                                      | `list(String)`                                                          |                 | N/A        |   yes    |
| rules       | A list of protocols and optional list of ports to which this rule applies. Each ports entry must be either an integer, range or an empty list `[]` to indicate all ports for the given protocol. | `list(Object{protocol=String, ports=list(Number), ports=list(String)})` |                 | N/A        |   yes    |

## Bonus Example
Using the local_file resource you can output the created rules to a JSON file and then use the provided PowerShell script to compare Firewall Rules managed by this Terraform Module and any existing rules in GCP to identify any unmanaged rules.

>*Note:* This section expects an `outputs` directory to exist as a valid target for JSON file output

```hcl
locals {
  firewall_rule_path = "./rules"
  firewall_rule_sets = fileset(local.firewall_rule_path, "*.json")
  firewall_rules = flatten([for rules_file in local.firewall_rule_sets : [
    for rule_index, rule in jsondecode(file("${local.firewall_rule_path}/${rules_file}")) :
    merge(rule, {
       file_name =  rules_file
       rule_index = rule_index
      })
    ]
  ])
}

module "firewall_rules" {
  source = "r-teller/firewall-rules/google"

  project_id = var.project_id
  network    = var.network

  firewall_rules = local.firewall_rules
}

# ### Creates JSON file that contains a list of all configuration attributes that will be used to create firewall rules 
resource "local_file" "firewall_rules_json" {
  content  = jsonencode(module.firewall_rules.firewall_rules_raw)
  filename = "${path.module}/outputs/managed.json"
}

### Creates JSON file that contains elements of the pre-processing ruleset used to troubleshoot rules with dynamically generated names
resource "local_file" "firewall_rules_map" {
  content  = jsonencode(module.firewall_rules.firewall_rules_map)
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