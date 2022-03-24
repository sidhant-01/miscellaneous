param($name)

$subscriptionID = (Get-AzContext).Subscription.id
$keys = @("primary","primaryReadonly",'secondary','secondaryReadonly')
foreach($key in $keys){
$response = Regenerate-CosmosDBKey -keyKind $key -cosmosDB $name["resourceName"] -resourceGroup $name["resourceGroupName"]
$regenerateCosmosKeyStatusCode = $response[0]
if ($regenerateCosmosKeyStatusCode -eq 200){
if ($response[1] -eq "MongoDB"){
$keySecretName =  $name["resourceName"] + "-$key" + "key"
$connectionStringSecretName =  $name["resourceName"] + "-$key" + "-mongo-connectionstring"
$connectionStringSecretValue = $response[3]
$secrets = @{$connectionStringSecretName=$connectionStringSecretValue;$keySecretName=$response[2]}
$kvSecretStatusCode = Create-KeyVaultSecret -vaultName $name["keyVault"] -secrets $secrets -azureADToken $name["kv_access_token"]
}
elseif ($response[1] -eq "Gremlin"){
$keySecretName =  $name["resourceName"] + "-$key" + "key"
$connectionStringSecretName =  $name["resourceName"] + "-$key" + "-gremlin-connectionstring"
$connectionStringSecretValue = $response[3]
$sqlConnectionStringSecretName =  $name["resourceName"] + "-$key" + "-sql-connectionstring"
$sqlConnectionStringSecretValue = $response[4]
$secrets = @{$sqlConnectionStringSecretName=$sqlConnectionStringSecretValue;$connectionStringSecretName=$connectionStringSecretValue;$keySecretName=$response[2]}
$kvSecretStatusCode = Create-KeyVaultSecret -vaultName $name["keyVault"] -secrets $secrets -azureADToken $name["kv_access_token"]
}
elseif ($response[1] -eq "Table"){
$keySecretName =  $name["resourceName"] + "-$key" + "key"
$connectionStringSecretName =  $name["resourceName"] + "-$key" + "-table-connectionstring"
$connectionStringSecretValue = $response[3]
$sqlConnectionStringSecretName =  $name["resourceName"] + "-$key" + "-sql-connectionstring"
$sqlConnectionStringSecretValue = $response[4]
$secrets = @{$sqlConnectionStringSecretName=$sqlConnectionStringSecretValue;$connectionStringSecretName=$connectionStringSecretValue;$keySecretName=$response[2]}
$kvSecretStatusCode = Create-KeyVaultSecret -vaultName $name["keyVault"] -secrets $secrets -azureADToken $name["kv_access_token"]
}
elseif ($response[1] -eq "cassandra"){
$keySecretName =  $name["resourceName"] + "-$key" + "key"
$connectionStringSecretName =  $name["resourceName"] + "-$key" + "-cassandra-connectionstring"
$connectionStringSecretValue = $response[3]
$sqlConnectionStringSecretName =  $name["resourceName"] + "-$key" + "-sql-connectionstring"
$sqlConnectionStringSecretValue = $response[4]
$secrets = @{$sqlConnectionStringSecretName=$sqlConnectionStringSecretValue;$connectionStringSecretName=$connectionStringSecretValue;$keySecretName=$response[2]}
$kvSecretStatusCode = Create-KeyVaultSecret -vaultName $name["keyVault"] -secrets $secrets -azureADToken $name["kv_access_token"]
}
else {
$keySecretName =  $name["resourceName"] + "-$key" + "key"
$connectionStringSecretName =  $name["resourceName"] + "-$key" + "-sqlCore-connectionstring"
$connectionStringSecretValue = $response[3]
$secrets = @{$sqlConnectionStringSecretName=$sqlConnectionStringSecretValue;$connectionStringSecretName=$connectionStringSecretValue;$keySecretName=$response[2]}
$kvSecretStatusCode = Create-KeyVaultSecret -vaultName $name["keyVault"] -secrets $secrets -azureADToken $name["kv_access_token"]
}
}
if(($regenerateCosmosKeyStatusCode -eq 200) -and ($kvSecretStatusCode -eq 200)){
$name["resourceName"] + " : Successfully regenerated cosmosDB key and inserted in key vault"
}
elseif ($regenerateCosmosKeyStatusCode -ne 200){
$name["resourceName"] + " : Error regenerating cosmosDB keys. Please check azure function logs for detailed error"
}
else{
$name["resourceName"] + " : Successfully regenerated cosmosDB key. Error occured while updating secret in key vault. Please check azure function logs for detailed error"
}
}