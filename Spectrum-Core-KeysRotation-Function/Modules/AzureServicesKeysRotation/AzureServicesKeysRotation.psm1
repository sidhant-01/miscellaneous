function Create-KeyVaultSecret{
param(
    [Parameter(Mandatory=$true)]
    [string] $vaultName,

    [Parameter(Mandatory=$true)]
    [hashtable] $secrets,

    [Parameter(Mandatory=$true)]
    [string] $azureADToken
)
if (!($azureADToken.StartsWith("Bearer"))){
    $azureADToken = "Bearer $azureADToken"
}
foreach($secret in $secrets.Keys){
    $secretValue = $secrets[$secret] 
    $kvSecretURL = "https://$vaultName.vault.azure.net/secrets/$secret" + "?api-version=7.2"
    $headers = @{ "Authorization" = $azureADToken }
    $body = "{
      `n    `"value`": `"$secretValue`"
      `n}"
    Write-Host "Creating/Updating secret $secret in key vault $vaultName started..."
    $response = Invoke-RestMethod -Method Put -Uri $kvSecretURL -Headers $headers -Body $body -ContentType "application/json"
    Write-Host "Creating/Updating secret $secret in key vault $vaultName ended successfully"
}
 return 200
}

function Generate-ManagedIdentityToken{
param(
    [Parameter(Mandatory=$true)]
    [string] $scope,

    [Parameter(Mandatory=$false)]
    [guid] $umiObjectID
)
try{
    $endpoint = $env:IDENTITY_ENDPOINT
    $header = $env:IDENTITY_HEADER
    $apiVersion = "2019-08-01"
    $headers = @{ 'X-Identity-Header' = $header }
    if ($umiObjectID){
    # URL for user managed identity
        $url = "$($endpoint)?client_id=$umiObjectID&resource=$scope&api-version=$apiVersion"
    }
    else{
    # URL for system managed identity
        $url = "$($endpoint)?resource=$scope&api-version=$apiVersion"
    }
    Write-Host "Generating managed identity token.."
    $response = Invoke-RestMethod -Method Get -Uri $url -Headers $headers
    Write-Host "Managed identity token generated successfully"
    return $response.access_token
}
catch{
    Write-Error "An error occurred generating managed identitiy token:"
    Write-Host $_
    Exit 1
}
}

function Regenerate-StorageAccountKey{
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('key1','key2', IgnoreCase = $true)]
    [string] $key,

    [Parameter(Mandatory=$true)]
    [string] $azureadToken,

    [Parameter(Mandatory=$true)]
    [string] $storageAccount,

    [Parameter(Mandatory=$true)]
    [string] $resourceGroup,

    [Parameter(Mandatory=$true)]
    [guid] $subscriptionID
)   
try{
    $key = $key.ToLower()
    $Uri = "https://management.azure.com/subscriptions/$subscriptionID/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccount/regenerateKey?api-version=2021-04-01"
    if (!($azureADToken.StartsWith("Bearer"))){
        $azureADToken = "Bearer $azureADToken"
    }
    $headers = @{ "Authorization" = $azureADToken }
    $body = "{
        `n    `"keyName`": `"$key`"
            `n}"
    Write-Host "Regenerating $key for storage account $storageAccount..."
    $response = Invoke-RestMethod -Method Post -Uri $Uri -Headers $headers -Body $body -ContentType "application/json" -StatusCodeVariable "storageKeysRequestStatusCode"
    Write-Host "$key for storage account $storageAccount regenerated successfully"
    $keyType = $response.keys | Where-Object { $_.keyName -eq $key }
    return $keyType.value, $storageKeysRequestStatusCode
    }
catch{
    Write-Host "An error occurred while regenerating $key for storage account $storageAccount"
    Write-Host $_
}
}

function Regenerate-CosmosDBKey{
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('primary','primaryReadonly','secondary','secondaryReadonly', IgnoreCase = $false)]
    [string] $keyKind,

    [Parameter(Mandatory=$true)]
    [string] $cosmosDB,

    [Parameter(Mandatory=$true)]
    [string] $resourceGroup

)   
try{
    $keyMap = @{"primary" = "PrimaryMasterKey"; "primaryReadonly" = "PrimaryReadonlyMasterKey"; "secondary" = "SecondaryMasterKey"; "secondaryReadonly" = "SecondaryReadonlyMasterKey"}
    $sqlConnectionStringMap = @{"primary" = "Primary SQL Connection String"; "primaryReadonly" = "Primary Read-Only SQL Connection String"; "secondary" = "Secondary SQL Connection String"; "secondaryReadonly" = "Secondary Read-Only SQL Connection String"}
    $db = Get-AzCosmosDBAccount -ResourceGroupName $resourceGroup -Name $cosmosDB
    Write-Host "Regenerating $keyKind key for cosmosDB $cosmosDB..."
    New-AzCosmosDBAccountKey  -ResourceGroupName $resourceGroup -Name $cosmosDB -KeyKind $keyKind | Out-Null
    Write-Host "$keyKind key for cosmosDB $cosmosDB regenerated successfully"
    $keys = Get-AzCosmosDBAccountKey -ResourceGroupName $resourceGroup -Name $cosmosDB -Type "Keys"
    $connectionStrings = Get-AzCosmosDBAccountKey -ResourceGroupName $resourceGroup -Name $cosmosDB -Type "ConnectionStrings"
    if ($db.Kind -eq "MongoDB"){
        $connectionStringMap = @{"primary" = "Primary MongoDB Connection String"; "primaryReadonly" = "Primary Read-Only MongoDB Connection String"; "secondary" = "Secondary MongoDB Connection String"; "secondaryReadonly" = "Secondary Read-Only MongoDB Connection String"}
        $keyType = $keyMap[$keyKind]
        $connectionStringKind = $connectionStringMap[$keyKind]
        return 200, "MongoDB", $keys.$keyType, $connectionStrings.$connectionStringKind
    }
    elseif ($db.Capabilities.Name.Contains("EnableGremlin")){
        $connectionStringMap = @{"primary" = "Primary Gremlin Connection String"; "primaryReadonly" = "Primary Read-Only Gremlin Connection String"; "secondary" = "Secondary Gremlin Connection String"; "secondaryReadonly" = "Secondary Read-Only Gremlin Connection String"}
        $keyType = $keyMap[$keyKind]
        $connectionStringKind = $connectionStringMap[$keyKind]
        $sqlConnectionStringKind = $sqlConnectionStringMap[$keyKind]
        return 200, "Gremlin", $keys.$keyType, $connectionStrings.$connectionStringKind, $connectionStrings.$sqlConnectionStringKind
    }
    elseif ($db.Capabilities.Name.Contains("EnableTable")){
        $connectionStringMap = @{"primary" = "Primary Table Connection String"; "primaryReadonly" = "Primary Read-Only Table Connection String"; "secondary" = "Secondary Table Connection String"; "secondaryReadonly" = "Secondary Read-Only Table Connection String"}
        $keyType = $keyMap[$keyKind]
        $connectionStringKind = $connectionStringMap[$keyKind]
        $sqlConnectionStringKind = $sqlConnectionStringMap[$keyKind]
        return 200, "Table", $keys.$keyType, $connectionStrings.$connectionStringKind, $connectionStrings.$sqlConnectionStringKind
    }
    elseif ($db.Capabilities.Name.Contains("EnableCassandra")){
        $connectionStringMap = @{"primary" = "Primary Cassandra Connection String"; "primaryReadonly" = "Primary Read-Only Cassandra Connection String"; "secondary" = "Secondary Cassandra Connection String"; "secondaryReadonly" = "Secondary Read-Only Cassandra Connection String"}
        $keyType = $keyMap[$keyKind]
        $connectionStringKind = $connectionStringMap[$keyKind]
        $sqlConnectionStringKind = $sqlConnectionStringMap[$keyKind]
        return 200, "cassandra", $keys.$keyType, $connectionStrings.$connectionStringKind, $connectionStrings.$sqlConnectionStringKind
    }
    else{
        $keyType = $keyMap[$keyKind]
        $sqlConnectionStringKind = $sqlConnectionStringMap[$keyKind]
        return 200, "sqlcore", $keys.$keyType, $connectionStrings.$sqlConnectionStringKind
    }
}
catch{
    Write-Host "An error occurred while regenerating $keyKind key for cosmosDB $cosmosDB"
    Write-Host $_
}
}


function Regenerate-ServiceBusKey{
param(
    [Parameter(Mandatory=$true)]
    [string] $authorizationRule,

    [Parameter(Mandatory=$true)]
    [string] $namespace,

    [Parameter(Mandatory=$true)]
    [string] $azureADToken,

    [Parameter(Mandatory=$true)]
    [ValidateSet('PrimaryKey','SecondaryKey', IgnoreCase = $false)]
    [string] $keyKind,

    [Parameter(Mandatory=$true)]
    [guid] $subscriptionID,

    [Parameter(Mandatory=$true)]
    [string] $resourceGroup
)
try{
    $keyMap = @{"PrimaryKey" = "primaryKey"; "SecondaryKey" = "secondaryKey"}
    $Uri = "https://management.azure.com/subscriptions/$subscriptionID/resourceGroups/$resourceGroup/providers/Microsoft.ServiceBus/namespaces/$namespace/AuthorizationRules/$authorizationRule/regenerateKeys?api-version=2017-04-01"
    if (!($azureADToken.StartsWith("Bearer"))){
        $azureADToken = "Bearer $azureADToken"
    }
    $headers = @{ "Authorization" = $azureADToken }
    $body = "{
        `n    `"keyType`": `"$keyKind`"
            `n}"
    Write-Host "Regenerating $keyKind for policy $authorizationRule for service bus $namespace..."
    $response = Invoke-RestMethod -Method Post -Uri $Uri -Headers $headers -Body $body -ContentType "application/json" -StatusCodeVariable "serviceBusKeysRequestStatusCode"
    Write-Host "$keyKind for policy $authorizationRule for service bus $namespace regenerated successfully"
    $keyType = $keyMap[$keyKind]
    return $response.$keyType, $serviceBusKeysRequestStatusCode
    }
catch{
    Write-Host "An error occurred while regenerating $keyKind for policy $authorizationRule for service bus $namespace"
    Write-Host $_
}
}

function Regenerate-FunctionAppHostKey{
param(

    [Parameter(Mandatory=$true)]
    [string] $azureADToken,

    [Parameter(Mandatory=$true)]
    [guid] $subscriptionID,

    [Parameter(Mandatory=$true)]
    [string] $resourceGroup,

    [Parameter(Mandatory=$true)]
    [string] $keyName,

    [Parameter(Mandatory=$true)]
    [string] $functionAppName
)

try{
    $Uri = "https://management.azure.com/subscriptions/$subscriptionID/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$functionAppName/host/default/functionKeys/$keyName" + "?api-version=2021-02-01"
    if (!($azureADToken.StartsWith("Bearer"))){
        $azureADToken = "Bearer $azureADToken"
    }
    $chars = "abcdefghijkmnopqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ23456789".ToCharArray()
    $keyValue = ""
    1..56 | ForEach {  $keyValue += $chars | Get-Random }
    $headers = @{ "Authorization" = $azureADToken }
    $body = "{
    `n    `"properties`":{
    `n    `"name`": `"$keyName`",
    `n    `"value`": `"$keyValue`"
    `n    }
    `n}"
    Write-Host "Regenerating host key $keyName for app $functionAppName..."
    $response = Invoke-RestMethod -Method Put -Uri $Uri -Headers $headers -Body $body -ContentType "application/json" -StatusCodeVariable "funcAppHostKeyRequestStatusCode"
    Write-Host "Host key $keyName for app $functionAppName regenerated successfully"
    return $response.properties.value, $funcAppHostKeyRequestStatusCode
    }
catch{
    Write-Host "An error occurred while regenerating host key $keyName for app $functionAppName"
    Write-Host $_
}
}

function Regenerate-FunctionAppFuncKey{
param(

    [Parameter(Mandatory=$true)]
    [string] $azureADToken,

    [Parameter(Mandatory=$true)]
    [guid] $subscriptionID,

    [Parameter(Mandatory=$true)]
    [string] $resourceGroup,

    [Parameter(Mandatory=$true)]
    [string] $keyName,

    [Parameter(Mandatory=$true)]
    [string] $functionAppName,

    [Parameter(Mandatory=$true)]
    [string] $functionName
)

try{
    $Uri = "https://management.azure.com/subscriptions/$subscriptionID/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$functionAppName/functions/$functionName/keys/$keyName" + "?api-version=2021-02-01"
    if (!($azureADToken.StartsWith("Bearer"))){
        $azureADToken = "Bearer $azureADToken"
    }
    $chars = "abcdefghijkmnopqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ23456789".ToCharArray()
    $keyValue = ""
    1..56 | ForEach {  $keyValue += $chars | Get-Random }
    $headers = @{ "Authorization" = $azureADToken }
    $body = "{
    `n    `"properties`":{
    `n    `"name`": `"$keyName`",
    `n    `"value`": `"$keyValue`"
    `n    }
    `n}"
    Write-Host "Regenerating function key $keyName for app $functionAppName for function $functionName..."
    $response = Invoke-RestMethod -Method Put -Uri $Uri -Headers $headers -Body $body -ContentType "application/json" -StatusCodeVariable "funcAppFuncKeyRequestStatusCode"
    Write-Host "function key $keyName for app $functionAppName for function $functionName regenerated successfully"
    return $response.properties.value, $funcAppFuncKeyRequestStatusCode
    }
catch{
    Write-Host "An error occurred while regenerating function key $keyName for app $functionAppName for function $functionName"
    Write-Host $_
}
}