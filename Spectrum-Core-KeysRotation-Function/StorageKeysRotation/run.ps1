param($name)

$subscriptionID = (Get-AzContext).Subscription.id
$keys = @("key1","key2")
foreach($key in $keys){
$response = Regenerate-StorageAccountKey -key $key -azureadToken $name["mgmt_access_token"] -storageAccount $name["resourceName"] -resourceGroup $name["resourceGroupName"] -subscriptionID $subscriptionID
$regenerateStorageKeyStatusCode = $response[1]
if ($regenerateStorageKeyStatusCode -eq 200){
$keySecretName =  $name["resourceName"] + "-$key"
$connectionStringSecretName =  $name["resourceName"] + "-$key" + "-connectionstring"
$connectionStringSecretValue = "DefaultEndpointsProtocol=https;AccountName=" + $name["resourceName"] + ";AccountKey=" + $response[0] + ";EndpointSuffix=core.windows.net"
$secrets = @{$connectionStringSecretName=$connectionStringSecretValue;$keySecretName=$response[0]}
$kvSecretStatusCode = Create-KeyVaultSecret -vaultName $name["keyVault"] -secrets $secrets -azureADToken $name["kv_access_token"]
}
if(($regenerateStorageKeyStatusCode -eq 200) -and ($kvSecretStatusCode -eq 200)){
$name["resourceName"] + " : Successfully regenerated storage account keys and inserted in key vault"
}
elseif ($regenerateStorageKeyStatusCode -ne 200){
$name["resourceName"] + " : Error regenerating storage account keys. Please check azure function logs for detailed error"
}
else{
$name["resourceName"] + " : Successfully regenerated storage account keys. Error occured while updating secrets in key vault. Please check azure function logs for detailed error"
}
}