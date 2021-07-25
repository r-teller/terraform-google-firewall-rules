$output=terraform output -json|ConvertFrom-JSON
$network=$output.environment.value.network
$project_id=$output.environment.value.project_id

gcloud compute firewall-rules list --project $project_id --filter="network~'projects/$project_id/global/networks/$network'" --format=json > .\outputs\active.json

$activeRules=Get-Content .\outputs\active.json | ConvertFrom-JSON
$managedRules=Get-Content .\outputs\managed.json | ConvertFrom-JSON

$unmanagedRules=$activeRules.name | ?{$managedRules.name -notcontains $_}

$_network=@{label="network";expression={$_.network.split("/")[-1]}}
$activeRules | Where-Object { $unmanagedRules -contains $_.name} | Select-Object  -Property Name,$_network,Disabled
