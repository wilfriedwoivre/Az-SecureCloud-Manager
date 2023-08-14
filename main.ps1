[CmdletBinding()]
param()

write-Information ""
Write-Information "##############################"
Write-Information "Import utils functions"
Write-Information "##############################"

Write-Information "Import configuration management function"
. $PSScriptRoot\utils\ConfigFile.ps1

Write-Information "Import module management function"
. $PSScriptRoot\utils\ModuleManagement.ps1

Write-Information "Import subscription modules"
. $PSScriptRoot\modules\subscriptions.ps1

write-Information ""
Write-Information "##############################"
Write-Information "Load configurations & environment variables"
Write-Information "##############################"


$config = Get-IniContent "$PSScriptRoot\config.ini"
Set-EnvVariablesFromEnvFile "$PSScriptRoot\.env"


Write-Information "Connect to Azure"
$contextName = "AzureSecureCloud"

$SecureStringPwd = $env:AZURE_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
$pscredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:AZURE_CLIENT_ID, $SecureStringPwd
Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $env:AZURE_TENANT_ID -ContextName $contextName -Force -WarningAction SilentlyContinue | Out-Null
Get-AzContext -Name $contextName | Set-AzContext | Out-Null

write-Information ""
Write-Information "##############################"
Write-Information "Get Logs subscription"
Write-Information "##############################"

$logSubscription = Find-Subscription -ManagementGroupId $config.DEFAULT.CoreManagementGroupId -Usage $config.SUBSCRIPTIONS_USAGE_TAGS.Logs -SubscriptionPoolManagementGroupId $config.DEFAULT.SubscriptionPoolManagementGroupId
