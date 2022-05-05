param
(
    [parameter(Mandatory = $True)] [String] $dbUser,
    [parameter(Mandatory = $True)] [String] $dbPassword,
    [parameter(Mandatory = $True)] [String] $dbServer,
    [parameter(Mandatory = $True)] [String] $sqlScriptsPath,
    [parameter(Mandatory = $False)] [String] $version
)

$VerbosePreference = "Continue"

<#
function GetLatestVersion
{
param
(
[Parameter(Mandatory=$true, Position=0)]
[string] $dbUser,
[Parameter(Mandatory=$true, Position=1)]
[string] $dbPassword,
[Parameter(Mandatory=$true, Position=2)]
[string] $dbName,
[Parameter(Mandatory=$true, Position=3)]
[string] $dbServer,
[Parameter(Mandatory=$true, Position=4)]
[string] $clientTableName
)
try{
$selectQuery = "SELECT ScriptVersion FROM $clientTableName;"
Write-Verbose "GetLatestVersion execution of  $selectQuery on $dbName database started"
$Versions = Invoke-Sqlcmd -Query $selectQuery -ServerInstance $dbServer -Username $dbUser -Password $dbPassword -Database $dbName
Write-Verbose "GetLatestVersion execution of  $selectQuery on $dbName database ended successfully"
if($Versions -ne $null){
$sortedVersions = $Versions.Version | Sort-Object -Descending
return $sortedVersions[0]
}
else{
return $null
}
}
catch{
Write-Error "GetLatestVersion execution of  $selectQuery on $dbName database ended with error."
Write-Host $PSItem.Exception.Message -ForegroundColor Red
exit 1
}
}
#>

function SqlInsert
{
param
(
[Parameter(Mandatory=$true, Position=0)]
[string] $dbUser,
[Parameter(Mandatory=$true, Position=1)]
[string] $dbPassword,
[Parameter(Mandatory=$true, Position=2)]
[string] $dbName,
[Parameter(Mandatory=$true, Position=3)]
[string] $dbServer,
[Parameter(Mandatory=$true, Position=4)]
[string] $clientTableName,
[Parameter(Mandatory=$true, Position=5)]
[string] $scriptName,
[Parameter(Mandatory=$true, Position=6)]
[string] $scriptVersion,
[Parameter(Mandatory=$true, Position=7)]
[string] $scriptHash
)
try{
$insertQuery = "INSERT INTO $clientTableName (ScriptName, ScriptVersion, ScriptHash) VALUES ('$scriptName','$scriptVersion','$scriptHash');"
Write-Verbose "SqlInsert of $insertQuery on $dbName database started"
$insertResult = Invoke-Sqlcmd -Query $insertQuery -ServerInstance $dbServer -Username $dbUser -Password $dbPassword -Database $dbName
Write-Verbose "SqlInsert of $insertQuery on $dbName database ended successfully"
return $insertResult
}
catch{
Write-Error "SqlInsert of $insertQuery on $dbName database ended with error."
Write-Host $PSItem.Exception.Message -ForegroundColor Red
exit 1
}
}


function SqlCreateTable
{
param
(
[Parameter(Mandatory=$true, Position=0)]
[string] $dbUser,
[Parameter(Mandatory=$true, Position=1)]
[string] $dbPassword,
[Parameter(Mandatory=$true, Position=2)]
[string] $dbName,
[Parameter(Mandatory=$true, Position=3)]
[string] $dbServer,
[Parameter(Mandatory=$true, Position=4)]
[string] $clientTableName
)
try{
$createTableQuery = 'CREATE TABLE ' + $clientTableName + ' (ID int IDENTITY(1,1),ScriptName varchar(255) NOT NULL,ScriptHash varchar(255) NOT NULL, ScriptVersion varchar(255),AppliedDateTime DATETIME NOT NULL DEFAULT (GETDATE()));'
Write-Verbose "SqlCreateTable execution of $createTableQuery on $dbName database started"
$createTableResult = Invoke-Sqlcmd -Query $createTableQuery -ServerInstance $dbServer -Username $dbUser -Password $dbPassword -Database $dbName
Write-Verbose "SqlCreateTable execution of $createTableQuery on $dbName database ended successfully"
return $createTableResult
}
catch{
Write-Error "SqlCreateTable execution of $createTableQuery on $dbName database ended with error."
Write-Host $PSItem.Exception.Message -ForegroundColor Red
exit 1
}
}

function SqlFetchTables
{
param
(
[Parameter(Mandatory=$true, Position=0)]
[string] $dbUser,
[Parameter(Mandatory=$true, Position=1)]
[string] $dbPassword,
[Parameter(Mandatory=$true, Position=2)]
[string] $dbName,
[Parameter(Mandatory=$true, Position=3)]
[string] $dbServer
)
try{
$fetchTablesQuery = "SELECT Name From sys.tables"
Write-Verbose "SqlFetchTables execution of $fetchTablesQuery on database $dbName started"
$fetchTableResult = Invoke-Sqlcmd -Query $fetchTablesQuery -ServerInstance $dbServer -Username $dbUser -Password $dbPassword -Database $dbName
Write-Verbose "SqlFetchTables execution of $fetchTablesQuery on database $dbName ended successfully"
return $fetchTableResult
}
catch{
Write-Error "SqlFetchTables execution of $fetchTablesQuery on $dbName database ended with error."
Write-Host $PSItem.Exception.Message -ForegroundColor Red
exit 1
}
}

function SqlExecuteScript
{
param
(
[Parameter(Mandatory=$true, Position=0)]
[string] $dbUser,
[Parameter(Mandatory=$true, Position=1)]
[string] $dbPassword,
[Parameter(Mandatory=$true, Position=2)]
[string] $dbName,
[Parameter(Mandatory=$true, Position=3)]
[string] $dbServer,
[Parameter(Mandatory=$true, Position=4)]
[string] $sqlFilePath
)
try{
$fileNameWithVersion = $sqlFilePath.Split("\")[-2] + "\" + $sqlFilePath.Split("\")[-1]
Write-Host "SqlExecuteScript execution of $fileNameWithVersion on $dbName database started" -ForegroundColor Green
$fileExecutionResult = Invoke-Sqlcmd -InputFile $sqlFilePath -ServerInstance $dbServer -Username $dbUser -Password $dbPassword -Database $dbName
Write-Host "SqlExecuteScript of $fileNameWithVersion on $dbName database ended successfully" -ForegroundColor Green
}
catch{
Write-Error "SqlExecuteScript execution of $fetchTablesQuery on $dbName database ended with error."
Write-Host $PSItem.Exception.Message -ForegroundColor Red
exit 1
}
}

function SqlScriptExecutionCheck
{
param
(
[Parameter(Mandatory=$true, Position=0)]
[string] $dbUser,
[Parameter(Mandatory=$true, Position=1)]
[string] $dbPassword,
[Parameter(Mandatory=$true, Position=2)]
[string] $dbName,
[Parameter(Mandatory=$true, Position=3)]
[string] $dbServer,
[Parameter(Mandatory=$true, Position=4)]
[string] $clientTableName,
[Parameter(Mandatory=$true, Position=5)]
[string] $sqlFileName,
[Parameter(Mandatory=$true, Position=6)]
[string] $scriptVersion,
[Parameter(Mandatory=$true, Position=7)]
[string] $scriptHash
)
try{
$selectQuery = "SELECT * FROM $clientTableName WHERE ScriptName = '$sqlFileName' AND ScriptVersion = '$scriptVersion' AND ScriptHash = '$scriptHash'"
Write-Verbose "SqlScriptExecutionCheck of $selectQuery on $dbName database started"
$selectQueryResult = Invoke-Sqlcmd -Query $selectQuery -ServerInstance $dbServer -Username $dbUser -Password $dbPassword -Database $dbName
if ($selectQueryResult -ne $null){
Write-Host "$scriptVersion\$sqlFileName already executed on $dbName database and will not be executed in this run" -ForegroundColor Green
Write-Verbose "SqlScriptExecutionCheck of $selectQuery on $dbName database ended successfully"
return $false
}
else{
Write-Host "$scriptVersion\$sqlFileName on $dbName database will be executed in this run" -ForegroundColor Green
Write-Verbose "SqlScriptExecutionCheck of $selectQuery on $dbName database ended successfully"
return $true
}
}
catch{
Write-Error "SqlScriptExecutionCheck execution of $selectQuery on $dbName database ended with error."
Write-Host $PSItem.Exception.Message -ForegroundColor Red
exit 1
}
}


if ([string]::IsNullOrEmpty($version)){
<# Release details from ADO #>
$releaseName = $env:RELEASE_RELEASENAME
$releaseEnvironment = $env:RELEASE_ENVIRONMENTNAME

<# Validate branch naming convention #>

$branchName = $releaseName.Split('-')
if (!($branchName[1].ToUpper() -notmatch '\w[-][V]\d{1,}[.]\d{1,}')){
Write-Host "Branch Name $branchName[1] is not as per the standard naming convention. Exiting deployment..." -ForegroundColor Red
exit 1
}
$clientNameAndVersion = $branchName[1].Split('_')
$clientName = $clientNameAndVersion[0]
$version = $clientNameAndVersion[1]
}
else{
$clientName = "sc"
$releaseEnvironment = $env:RELEASE_ENVIRONMENTNAME
}
$folderVersions = Get-ChildItem -Path $sqlScriptsPath -Directory -Force -Filter "$version*"

if($folderVersions){
foreach($folderVersion in $folderVersions){
$deploymentStepCsvPath = $sqlScriptsPath + "\" + $folderVersion + "\" + 'DeploymentSteps.csv'
$databases = @()
$deploymentCsv = Import-Csv -Path $deploymentStepCsvPath
Write-Host "Execution Started for $folderVersion" -ForegroundColor Green
$databases = $deploymentCsv | Select Database -Unique

<# Verify/Create client specific table #>

foreach ($database in $databases){
$tables = SqlFetchTables $dbUser $dbPassword $database.Database $dbServer
if (!($Tables.Name -contains $clientName)){
SqlCreateTable $dbUser $dbPassword $database.Database $dbServer $clientName
}
else{
Write-Verbose "Client Table $clientName already exists in $database"
}
}

<# Script execution on dev environment #>

if($releaseEnvironment.ToUpper() -eq "DEV"){
foreach($scriptAndDB in $deploymentCsv){
$scriptName = $scriptAndDB.FileName
$sqlFilePath = $sqlScriptsPath + '\' + $folderVersion + "\" + $scriptName
$scriptHash = Get-FileHash -Path $sqlFilePath
if(-not(($scriptName -match '_qa') -or ($scriptName -match '_uat') -or ($scriptName -match '_prod'))){
$exectionStatus = SqlScriptExecutionCheck $dbUser $dbPassword $scriptAndDB.Database $dbServer $clientName $scriptName $folderVersion $scriptHash.Hash
if ($exectionStatus)
{
SqlExecuteScript $dbUser $dbPassword $scriptAndDB.Database $dbServer $sqlFilePath
SqlInsert $dbUser $dbPassword $scriptAndDB.Database $dbServer $clientName $scriptName $folderVersion $scriptHash.Hash
}
}
}
}

<# Script execution on qa environment #>

if($releaseEnvironment.ToUpper() -eq "QA"){
foreach($scriptAndDB in $deploymentCsv){
$scriptName = $scriptAndDB.FileName
if(-not(($scriptName -match '_dev') -or ($scriptName -match '_uat') -or ($scriptName -match '_prod'))){
$exectionStatus = SqlScriptExecutionCheck $dbUser $dbPassword $scriptAndDB.Database $dbServer $clientName $scriptName
if ($exectionStatus)
{
$scriptToBeExecuted = $scriptAndDB.FileName
$sqlFilePath = $sqlScriptsPath + '\' + $scriptToBeExecuted
SqlExecuteScript $dbUser $dbPassword $scriptAndDB.Database $dbServer $sqlFilePath
SqlInsert $dbUser $dbPassword $scriptAndDB.Database $dbServer $clientName $scriptName $scriptHash
}
}
}
}

<# Script execution on UAT environment #>

if($releaseEnvironment.ToUpper() -eq "UAT"){
foreach($scriptAndDB in $deploymentCsv){
$scriptName = $scriptAndDB.FileName
if(-not(($scriptName -match '_dev') -or ($scriptName -match '_qa') -or ($scriptName -match '_prod'))){
$exectionStatus = SqlScriptExecutionCheck $dbUser $dbPassword $scriptAndDB.Database $dbServer $clientName $scriptName
if ($exectionStatus)
{
$scriptToBeExecuted = $scriptAndDB.FileName
$sqlFilePath = $sqlScriptsPath + '\' + $scriptToBeExecuted
SqlExecuteScript $dbUser $dbPassword $scriptAndDB.Database $dbServer $sqlFilePath
SqlInsert $dbUser $dbPassword $scriptAndDB.Database $dbServer $clientName $scriptName
}
}
}
}

<# Script execution on prod environment #>

if($releaseEnvironment.ToUpper() -eq "PROD"){
foreach($scriptAndDB in $deploymentCsv){
$scriptName = $scriptAndDB.FileName
if(-not(($scriptName -match '_dev') -or ($scriptName -match '_qa') -or ($scriptName -match '_uat'))){
$exectionStatus = SqlScriptExecutionCheck $dbUser $dbPassword $scriptAndDB.Database $dbServer $clientName $scriptName
if ($exectionStatus)
{
$scriptToBeExecuted = $scriptAndDB.FileName
$sqlFilePath = $sqlScriptsPath + '\' + $scriptToBeExecuted
SqlExecuteScript $dbUser $dbPassword $scriptAndDB.Database $dbServer $sqlFilePath
SqlInsert $dbUser $dbPassword $scriptAndDB.Database $dbServer $clientName $scriptName
}
}
}
}
}
}
else{
Write-Host "No folder found in the directory that starts with $version" -ForegroundColor Green
}