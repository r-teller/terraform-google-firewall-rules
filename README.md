# Google Cloud VPC Firewall Rules
This Terraform module simplifies the creation and management of Google Cloud Platform (GCP) firewall rules using JSON configurations as the primary method for rule definition. It supports a variety of source and target specifications, enabling detailed control over network traffic.

It supports mixed values in both the source and target JSON fields and uses string matching to determine the type. The supported types and their determination logic are as follows:
-  service_accounts = `if length(split("@", x)) > 1`
-  tags             = `if length(split("@", x)) < 2 && !can(cidrnetmask(x))`
-  subnet_ranges    = `if can(cidrnetmask(x))`

**Important Note:** Mixing `service_accounts` and `tags` within the same rule is not supported. Each rule must exclusively use one type of identifier to ensure proper functionality and avoid configuration conflicts.

## JSON Generator
Generate your firewall rule configurations using our online tool:
[Firewall Rules JSON Generator](https://r-teller.github.io/terraform-google-firewall-rules)

- [Example Rule allowing TCP/UDP from IAP](https://r-teller.github.io/terraform-google-firewall-rules/?formData=W3siZGlzYWJsZWQiOmZhbHNlLCJhY3Rpb24iOiJBTExPVyIsImRpcmVjdGlvbiI6IklOR1JFU1MiLCJydWxlcyI6W3sicHJvdG9jb2wiOiJUQ1AiLCJwb3J0cyI6W119LHsicHJvdG9jb2wiOiJVRFAifV0sInNvdXJjZXMiOlsiMzUuMjM1LjI0MC4wLzIwIl0sInRhcmdldHMiOltdLCJwcmlvcml0eSI6NjU1MzAsImxvZ19jb25maWciOiJFWENMVURFX0FMTF9NRVRBREFUQSIsImlkIjoiZmZmYiIsImRlc2NyaXB0aW9uIjoiVGhpcyBydWxlIHdpbGwgYWxsb3cgSUFQIHJhbmdlcyBhY2Nlc3MgdG8gYWxsIFZNcyBvbiBhbGwgVENQL1VEUCBQb3J0cy4iLCJuYW1lIjoiYWxsb3ctYWxsLXRjcC11ZHAtZnJvbS1nY3AtaWFwIn1d)

## JSON Schema Documentation
For detailed schema information and rule configuration options, visit:
[Firewall Rules JSON Schema Documentation](https://r-teller.github.io/terraform-google-firewall-rules/documentation/)

## Include Implicit Addresses

This module automatically includes default address ranges for unspecified sources in ingress rules and destinations in egress rules, aligning with Google Cloud's default behavior. This feature enhances rule clarity and can be toggled using the `include_implicit_addresses` variable.

### Configuring Implicit Address Inclusion

The inclusion of default address ranges can be controlled using the `include_implicit_addresses` variable in combination with the `ip_version` variable. This allows for flexible configuration:

- **Enabled (default)**: The module will automatically add default address ranges to the rule attributes for unspecified sources in ingress rules and unspecified destinations in egress rules, making the default behavior explicit and ensuring comprehensive coverage.
- **Disabled**: By setting `var.include_implicit_addresses` to `false`, users can opt out of this automatic inclusion. This will not change how Google handles or processes the rules.

### IPv6 Support

This module supports both IPv4 and IPv6 firewall rules through the `implicit_ip_version` variable:

- **AUTO (default)**: Automatically detects the IP version based on CIDRs specified in the rule. When sources or targets contain only tags/service accounts (no CIDRs), the module infers the IP version from the opposite field. If the opposite field contains IPv6 CIDRs (`::`), it uses `::/0`; otherwise, it uses `0.0.0.0/0`.
- **IPV4**: Explicitly uses `0.0.0.0/0` for implicit addresses
- **IPV6**: Explicitly uses `::/0` for implicit addresses

**Important**:
- GCP firewall rules are **single-stack only** - each rule can use either IPv4 or IPv6 addresses, not both
- Implicit addresses are **only added when tags or service accounts are specified** (not when sources/targets are completely empty)
- The module validates that you don't mix IPv4 and IPv6 CIDRs in the same rule
- To support both IP versions, create separate firewall rules for each

#### Auto-Detection Examples

With `implicit_ip_version = "AUTO"` (default):

```json
// Tag-based rule with IPv6 targets → sources get ::/0
{
  "sources": ["web-server"],      // tag (no CIDR)
  "targets": ["fd00::/8"],        // IPv6 CIDR
  "rules": [...]
}
// Result: sources = ["::/0"], targets = ["fd00::/8"] ✅

// Tag-based rule with IPv4 sources → targets get 0.0.0.0/0
{
  "sources": ["10.0.0.0/8"],      // IPv4 CIDR
  "targets": ["backend"],         // tag (no CIDR)
  "rules": [...]
}
// Result: sources = ["10.0.0.0/8"], targets = ["0.0.0.0/0"] ✅

// Empty sources and targets → no implicit addresses added
{
  "sources": [],
  "targets": [],
  "rules": [...]
}
// Result: sources = [], targets = [] (GCP will apply default 0.0.0.0/0)

// INVALID: Mixing IPv4 and IPv6 CIDRs → Terraform validation error
{
  "sources": ["10.0.0.0/8", "fd00::/8"],  // ❌ Mixed IP versions
  "targets": [],
  "rules": [...]
}
// Error: Cannot mix IPv4 and IPv6 CIDRs in the same firewall rule
```

You can specify IPv6 CIDR ranges directly in your firewall rules' sources and targets fields. The module's CIDR detection automatically recognizes both IPv4 and IPv6 formats using Terraform's `cidrsubnet()` function.

## Combining Subnet Ranges with Service Accounts or Tags
When specifying firewall rules, it is possible to combine `subnet_ranges` with either `service_accounts` or `tags` to enhance the flexibility and granularity of your network's security configuration for both ingress and egress traffic. If `subnet_ranges` are used in conjunction with `service_accounts` or `tags`, the rule applies to traffic originating from the specified IP ranges or to instances associated with the specified service accounts or tags. This combination allows for specifying rules that target both broad network segments (via IP ranges) and specific sets of instances (via service accounts or tags), ensuring precise and effective control over access and traffic flow within your network.

- For Ingress Traffic: A rule matches if the source of the traffic is within the specified `subnet_ranges` or if it originates from instances identified by the specified `service_accounts` or `tags`.
- For Egress Traffic: A rule applies if the destination of the traffic is within the specified `subnet_ranges` or if it targets instances identified by the specified `service_accounts` or `tags`.

## Example JSON Firewall Rule
Firewall Rules must be formatted as valid JSON and added to a directory called `rules`. The `id` field is used to help uniquely identify the firewall rule within a specified environment, prefix, project when potential collisions could occur.

### IPv4 Example
```json
[
    {
        "id": "fffb",
        "description": "This rule will allow IAP ranges access to all VMs within 192.168.0.0/16 on all ports.",
        "action": "ALLOW",
        "direction": "INGRESS",
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

### IPv6 Example
```json
[
    {
        "id": "ipv6-ssh",
        "description": "Allow SSH from specific IPv6 range to all VMs",
        "action": "ALLOW",
        "direction": "INGRESS",
        "log_config": "EXCLUDE_ALL_METADATA",
        "priority": 1000,
        "sources": [
            "2001:db8::/32"
        ],
        "targets": [],
        "rules": [
            {
                "protocol": "TCP",
                "ports": ["22"]
            }
        ]
    }
]
```

### Supporting Both IPv4 and IPv6
Since GCP requires separate rules for IPv4 and IPv6, create two rules:

```json
[
    {
        "id": "https-ipv4",
        "description": "Allow HTTPS from IPv4 addresses",
        "action": "ALLOW",
        "direction": "INGRESS",
        "log_config": "DISABLED",
        "priority": 1000,
        "sources": [
            "10.0.0.0/8"
        ],
        "targets": [],
        "rules": [
            {
                "protocol": "TCP",
                "ports": ["443"]
            }
        ]
    },
    {
        "id": "https-ipv6",
        "description": "Allow HTTPS from IPv6 addresses",
        "action": "ALLOW",
        "direction": "INGRESS",
        "log_config": "DISABLED",
        "priority": 1000,
        "sources": [
            "2001:db8::/32"
        ],
        "targets": [],
        "rules": [
            {
                "protocol": "TCP",
                "ports": ["443"]
            }
        ]
    }
]
```

## Usage
To use this module in your Terraform configuration, specify the source, project ID, network, and firewall rules as shown below:
 

```hcl
locals {
  firewall_rule_path = "./rules"
  firewall_rule_sets = fileset(local.firewall_rule_path, "*.json")
  firewall_rules = flatten([for rules in local.firewall_rule_sets : [
    for idx, rule in jsondecode(file("${local.firewall_rule_path}/${rules}")) :
    merge(rule, { 
      file_name = split(".", rules)[0], 
      rule_index = idx 
      })
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

  # Optional field to control IP version for implicit addresses
  # Only applies when tags/service-accounts are specified (not when sources/targets are empty)
  # Options: "AUTO" (default - auto-detects from rule CIDRs), "IPV4", "IPV6"
  # Note: GCP firewall rules are single-stack only
  implicit_ip_version = "AUTO"

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
| Name                       | Description                                                                                                                         | Type     | Default      | Required |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------ | :------: |
| project_id                 | Project id of the project that holds the network.                                                                                   | `string` | `null`       |    no    |
| network                    | Name of the network this set of firewall rules applies to.                                                                          | `string` | `null`       |    no    |
| prefix                     | This field denotes the prefix tag for firewall rule, used for dynamic name generation.                                              | `string` | `null`       |    no    |
| environment                | This field denotes the environment tag for firewall rule, used for dynamic name generation.                                         | `string` | `null`       |    no    |
| firewall_rules             | Firewall Rule object to be passed to the Firewall Rules Module                                                                      | `object` | N/A          |   yes    |
| include_implicit_addresses | Toggle to include implicit source or target addresses within firewall rules based on implicit_ip_version setting.                  | `bool`   | `true`       |    no    |
| implicit_ip_version        | IP version for implicit addresses when tags/SAs are specified. AUTO auto-detects from rule CIDRs. Options: AUTO, IPV4, IPV6. Single-stack only. | `string` | `AUTO`       |    no    |
| use_legacy_naming          | Toggle to use legacy naming conventions for firewall rules.                                                                         | `bool`   | `false`      |    no    |
| override_dynamic_naming    | Configuration object for dynamic naming of firewall rules, specifying which attributes to include.                                  | `object` | See below    |    no    |

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
| action      | The action for the firewall rule                                                                                                                                                                 | `ALLOW` or `DENY`                                                       |                 | N/A        |   yes    |
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


