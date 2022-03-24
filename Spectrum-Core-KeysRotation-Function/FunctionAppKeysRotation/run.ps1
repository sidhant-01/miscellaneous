param($name)

$subscriptionID = (Get-AzContext).Subscription.id
$keyType = $name["keyType"]
if ($keyType.ToUpper() -eq 'HOSTKEY'){
$response = Regenerate-FunctionAppHostKey -functionAppName $name["resourceName"] -keyName $name["keyName"] -resourceGroup $name["resourceGroupName"] -azureADToken $name["mgmt_access_token"] -subscriptionID $subscriptionID
$regenerateFunctionKeyStatusCode = $response[1]
}
else {
$response = Regenerate-FunctionAppFuncKey -functionAppName $name["resourceName"] -keyName $name["keyName"] -resourceGroup $name["resourceGroupName"] -azureADToken $name["mgmt_access_token"] -functionName $name["functionName"] -subscriptionID $subscriptionID
$regenerateFunctionKeyStatusCode = $response[1]
}
if ($regenerateFunctionKeyStatusCode -eq 200 -or $regenerateFunctionKeyStatusCode -eq 201){
$kvSecretStatusCode = Create-KeyVaultSecret -vaultName $name["keyVault"] -secretName $name["secretName"] -secretValue $response[0] -azureADToken $name["kv_access_token"]
}
if(($regenerateFunctionKeyStatusCode -eq 200 -or $regenerateFunctionKeyStatusCode -eq 201) -and ($kvSecretStatusCode -eq 200)){
$name["resourceName"] + " : Successfully regenerated function key and inserted in key vault"
}
elseif ($regenerateFunctionKeyStatusCode -ne 200 -or $regenerateFunctionKeyStatusCode -nq 201){
$name["resourceName"] + " : Error regenerating function keys. Please check azure function logs for detailed error"
}
else{
$name["resourceName"] + " : Successfully regenerated function key. Error occured while updating secret in key vault. Please check azure function logs for detailed error"
}