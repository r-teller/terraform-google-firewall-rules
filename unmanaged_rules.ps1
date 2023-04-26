$managed_firewall_rules = (Get-Content .\outputs\managed.json | ConvertFrom-json) | ForEach-Object { $_.psobject.Properties.Value }

$unique_networks = @()
foreach ($managed_firewall_rule in $managed_firewall_rules) {
    if (-not ($unique_networks | Where-Object { $_.network -eq $managed_firewall_rule.network.split("/")[-1] -and $_.project -eq $managed_firewall_rule.project })) {
        $unique_networks += @{ 
            "project"   = $managed_firewall_rule.project; 
            "self_link" = $managed_firewall_rule.self_link; 
            "network"   = $managed_firewall_rule.network.split("/")[-1];
        }
    }
}

$active_firewall_rules = @()
foreach ($unique_network in  $unique_networks) {
    $network = "projects/$($unique_network.project)/global/networks/$($unique_network.network)"
    $active_firewall_rules += (gcloud compute firewall-rules list --project $unique_network.project --filter="network~$network" --format=json | ConvertFrom-Json)
}

$_network=@{label="Network";expression={$_.network.split("/")[-1]}}
$_project=@{label="Project";expression={$_.network.split("/")[6]}}
$_name=@{label="Unmanaged Firewall Rule";expression={$_.name}}
$_disabled=@{label="Disabled";expression={$_.Disabled}}

$active_firewall_rules | Where-Object { $managed_firewall_rules.self_link -notcontains $_.selfLink } | Select-Object  -Property $_project, $_network, $_name, $_disabled

