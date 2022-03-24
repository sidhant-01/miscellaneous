param($name)

$subscriptionID = (Get-AzContext).Subscription.id
$keys = @("PrimaryKey","SecondaryKey")
foreach($key in $keys){
$response = Regenerate-ServiceBusKey -keyKind $key -azureadToken $name["mgmt_access_token"] -namespace $name["resourceName"] -resourceGroup $name["resourceGroupName"] -authorizationRule "RootManageSharedAccessKey" -subscriptionID $subscriptionID
$regenerateServiceBusKeyStatusCode = $response[1]
if ($regenerateServiceBusKeyStatusCode -eq 200){
    $keySecretName =  $name["resourceName"] + "-$key"
    $connectionStringSecretName =  $name["resourceName"] + "-$key" + "-connectionstring"
    $connectionStringSecretValue = "Endpoint=sb://" + $name["resourceName"] + ".servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=" + $response[0]
    $secrets = @{$connectionStringSecretName=$connectionStringSecretValue;$keySecretName=$response[0]}
    $kvSecretStatusCode = Create-KeyVaultSecret -vaultName $name["keyVault"] -secrets $secrets -azureADToken $name["kv_access_token"]
}
if(($regenerateServiceBusKeyStatusCode -eq 200) -and ($kvSecretStatusCode -eq 200)){
$name["resourceName"] + " : Successfully regenerated service bus key and inserted in key vault"
}
elseif ($regenerateServiceBusKeyStatusCode -ne 200){
$name["resourceName"] + " : Error regenerating service bus key. Please check azure function logs for detailed error"
}
else{
$name["resourceName"] + " : Successfully regenerated service bus key. Error occured while updating secret in key vault. Please check azure function logs for detailed error"
}
}