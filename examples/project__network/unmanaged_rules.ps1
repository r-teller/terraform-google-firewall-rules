$output=terraform output -json|ConvertFrom-JSON
$network=$output.environment.value.network
$project_id=$output.environment.value.project_id

gcloud compute firewall-rules list --project $project_id --filter="network~'projects/$project_id/global/networks/$network'" --format=json > .\outputs\active.json

$activeRules=Get-Content .\outputs\active.json | ConvertFrom-JSON
$managedRules=Get-Content .\outputs\managed.json | ConvertFrom-JSON

$unmanagedRules=$activeRules.name | Where-Object {$managedRules.name -notcontains $_}

$_network=@{label="network";expression={$_.network.split("/")[-1]}}
$_project=@{label="project";expression={$_.network.split("/")[6]}}
$_name=@{label="unmanaged firewall rule";expression={$_.name}}
$activeRules | Where-Object { $unmanagedRules -contains $_.name} | Select-Object  -Property $_project,$_network,$_name,Disabled
