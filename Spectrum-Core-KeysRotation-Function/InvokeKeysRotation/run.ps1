using namespace System.Net

param($Request, $TriggerMetadata)

$FunctionName = $Request.Params.FunctionName
$body = $Request.Body | ConvertTo-Json
$InstanceId = Start-NewOrchestration -FunctionName $FunctionName -Input $body
Write-Host "Started orchestration with ID = '$InstanceId'"

$Response = New-OrchestrationCheckStatusResponse -Request $Request -InstanceId $InstanceId
Push-OutputBinding -Name Response -Value $Response
