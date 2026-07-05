<#
.SYNOPSIS
Collects post-deployment evidence for Azure Landing Zone.

.DESCRIPTION
Exports selected Azure CLI outputs to JSON and creates a simple Markdown summary.
#>

[CmdletBinding()]
param(
    [string] $ProjectName = 'alz',
    [string] $Environment = 'dev',
    [string] $SubscriptionId = '',
    [string] $EvidencePath = "./evidence/collect-evidence/collect-evidence-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string] $Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Invoke-AzEvidence {
    param(
        [Parameter(Mandatory)] [string[]] $Arguments,
        [Parameter(Mandatory)] [string] $OutFile,
        [switch] $IgnoreErrors
    )

    Write-Host "az $($Arguments -join ' ')" -ForegroundColor DarkGray
    $output = & az @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $output | Out-File -FilePath $OutFile -Encoding utf8

    if ($exitCode -ne 0 -and -not $IgnoreErrors) {
        throw "Azure CLI command failed. Output saved to $OutFile"
    }
}

New-Item -ItemType Directory -Path $EvidencePath -Force | Out-Null

if ($SubscriptionId) {
    & az account set --subscription $SubscriptionId --only-show-errors
    if ($LASTEXITCODE -ne 0) { throw 'Unable to set subscription.' }
}

$accountJson = & az account show --only-show-errors
if ($LASTEXITCODE -ne 0) { throw 'Unable to read active Azure subscription.' }
$account = $accountJson | ConvertFrom-Json
$subId = $account.id
$scope = "/subscriptions/$subId"

$monitorRg = "rg-$ProjectName-$Environment-monitor"
$lawName = "law-$ProjectName-$Environment"
$diagName = "diag-$ProjectName-$Environment-sub-activity"
$budgetName = "bud-$ProjectName-$Environment"

Write-Step 'Collect subscription and deployment evidence'
$accountJson | Out-File -FilePath (Join-Path $EvidencePath '01-subscription.json') -Encoding utf8
Invoke-AzEvidence -Arguments @('deployment', 'sub', 'list', '--query', "[?contains(name, 'alz-lite') || contains(name, '$ProjectName')].[name,properties.provisioningState,properties.timestamp]", '--output', 'json') -OutFile (Join-Path $EvidencePath '02-subscription-deployments.json') -IgnoreErrors

Write-Step 'Collect resource groups and resources'
Invoke-AzEvidence -Arguments @('group', 'list', '--query', "[?starts_with(name, 'rg-$ProjectName-$Environment-')].{name:name, location:location, tags:tags}", '--output', 'json') -OutFile (Join-Path $EvidencePath '03-resource-groups.json') -IgnoreErrors
Invoke-AzEvidence -Arguments @('resource', 'list', '--tag', "Project=$ProjectName", '--output', 'json') -OutFile (Join-Path $EvidencePath '04-resources-by-project-tag.json') -IgnoreErrors

Write-Step 'Collect monitoring evidence'
Invoke-AzEvidence -Arguments @('monitor', 'log-analytics', 'workspace', 'show', '--resource-group', $monitorRg, '--workspace-name', $lawName, '--output', 'json') -OutFile (Join-Path $EvidencePath '05-log-analytics-workspace.json') -IgnoreErrors
Invoke-AzEvidence -Arguments @('rest', '--method', 'get', '--url', "https://management.azure.com$($scope)/providers/Microsoft.Insights/diagnosticSettings/$($diagName)?api-version=2021-05-01-preview", '--output', 'json') -OutFile (Join-Path $EvidencePath '06-subscription-diagnostic-setting.json') -IgnoreErrors

Write-Step 'Collect governance evidence'
Invoke-AzEvidence -Arguments @('policy', 'assignment', 'list', '--scope', $scope, '--query', "[?starts_with(name, 'pa-$ProjectName-$Environment-')].{name:name, displayName:displayName, policyDefinitionId:policyDefinitionId, parameters:parameters}", '--output', 'json') -OutFile (Join-Path $EvidencePath '07-policy-assignments.json') -IgnoreErrors
Invoke-AzEvidence -Arguments @('role', 'assignment', 'list', '--scope', $scope, '--query', "[?contains(roleDefinitionName, 'Reader') || contains(roleDefinitionName, 'Contributor')].{principalName:principalName, role:roleDefinitionName, scope:scope}", '--output', 'json') -OutFile (Join-Path $EvidencePath '08-rbac-assignments-scope.json') -IgnoreErrors

Write-Step 'Collect cost evidence'
Invoke-AzEvidence -Arguments @('rest', '--method', 'get', '--url', "https://management.azure.com$($scope)/providers/Microsoft.Consumption/budgets/$($budgetName)?api-version=2024-08-01", '--output', 'json') -OutFile (Join-Path $EvidencePath '09-budget.json') -IgnoreErrors

$summaryPath = Join-Path $EvidencePath 'SUMMARY.md'
@"
# Azure Landing Zone Lite - Evidence Summary

Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Subscription

- Name: $($account.name)
- ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
- Project: $ProjectName
- Environment: $Environment

## Evidence files

| File | Purpose |
|---|---|
| 01-subscription.json | Active subscription context |
| 02-subscription-deployments.json | Subscription-scope deployment history |
| 03-resource-groups.json | Project resource groups and tags |
| 04-resources-by-project-tag.json | Resources with project tag |
| 05-log-analytics-workspace.json | Log Analytics Workspace configuration |
| 06-subscription-diagnostic-setting.json | Activity Log diagnostic setting |
| 07-policy-assignments.json | Azure Policy assignments |
| 08-rbac-assignments-scope.json | RBAC assignments visible at subscription scope |
| 09-budget.json | Subscription budget configuration |


"@ | Out-File -FilePath $summaryPath -Encoding utf8

Write-Step 'Evidence collection completed'
Write-Host "Evidence saved to: $EvidencePath" -ForegroundColor Yellow
Write-Host "Summary: $summaryPath" -ForegroundColor Yellow
