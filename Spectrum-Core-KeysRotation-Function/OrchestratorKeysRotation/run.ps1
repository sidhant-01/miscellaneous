param($Context)

$output = @()

$input = $Context.Input
$body = ConvertFrom-Json $input
$mgmtScope = "https://management.azure.com"
$kvScope = "https://vault.azure.net"
$mgmtToken = Generate-ManagedIdentityToken -scope $mgmtScope -umiObjectID "53eb46c6-c65c-4d07-bd92-f1c9011584b6"
$kvToken = Generate-ManagedIdentityToken -scope $kvScope -umiObjectID "53eb46c6-c65c-4d07-bd92-f1c9011584b6"
foreach($val in $body){
    $val | add-member -Name "mgmt_access_token" -value $mgmtToken -MemberType NoteProperty
    $val | add-member -Name "kv_access_token" -value $kvToken -MemberType NoteProperty
    if (($val.resourceType -eq "Microsoft.Storage/storageAccounts") -and ($val.rotate -eq $true)){
        $output += Invoke-ActivityFunction -FunctionName 'StorageKeysRotation' -Input $val
    }
    elseif (($val.resourceType -eq "Microsoft.DocumentDB/databaseAccounts") -and ($val.rotate -eq $true)){
        $output += Invoke-ActivityFunction -FunctionName 'CosmosDBKeysRotation' -Input $val
    }
    elseif(($val.resourceType -eq "Microsoft.ServiceBus/namespaces") -and ($val.rotate -eq $true)){
        $output += Invoke-ActivityFunction -FunctionName 'ServiceBusKeysRotation' -Input $val
    }
    elseif(($val.resourceType -eq "Microsoft.Web/sites/functionapp") -and ($val.rotate -eq $true)){
        $output += Invoke-ActivityFunction -FunctionName 'FunctionAppKeysRotation' -Input $val
    }
    else{
        # Do Nothing
    }
}

$output
