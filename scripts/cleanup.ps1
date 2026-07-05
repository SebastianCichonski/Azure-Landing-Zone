<#
.SYNOPSIS
Removes Azure Landing Zone lab resources.

.DESCRIPTION
Deletes project resource groups, subscription diagnostic settings, policy assignments and budget.
RBAC removal is optional and requires principal object IDs.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string] $ProjectName = 'alz',
    [string] $Environment = 'dev',
    [string] $Location = 'westeurope',
    [string] $SubscriptionId = '',
    [switch] $RemoveRbac,
    [string[]] $PrincipalObjectIds = @(),
    [switch] $NoWait,
    [string] $EvidencePath = "./evidence/cleanup-evidence/cleanup-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string] $Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Invoke-AzSafe {
    param(
        [Parameter(Mandatory)] [string[]] $Arguments,
        [switch] $IgnoreErrors,
        [string] $OutFile = ''
    )

    Write-Host "az $($Arguments -join ' ')" -ForegroundColor DarkGray
    $output = & az @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    if ($OutFile) {
        $output | Out-File -FilePath $OutFile -Encoding utf8
    }

    if ($exitCode -ne 0 -and -not $IgnoreErrors) {
        $output | Write-Host -ForegroundColor Red
        throw "Azure CLI command failed with exit code $exitCode."
    }

    if ($exitCode -ne 0 -and $IgnoreErrors) {
        Write-Host "Skipped or already removed." -ForegroundColor DarkYellow
    }

    return $output
}

New-Item -ItemType Directory -Path $EvidencePath -Force | Out-Null

if ($SubscriptionId) {
    Write-Step 'Set subscription'
    Invoke-AzSafe -Arguments @('account', 'set', '--subscription', $SubscriptionId, '--only-show-errors') | Out-Null
}

$accountJson = Invoke-AzSafe -Arguments @('account', 'show', '--only-show-errors') -OutFile (Join-Path $EvidencePath 'account-before-cleanup.json')
$account = $accountJson | ConvertFrom-Json
$subId = $account.id
$scope = "/subscriptions/$subId"

Write-Host "Subscription: $($account.name) [$subId]" -ForegroundColor Yellow

$requiredTags = @('Owner', 'Environment', 'CostCenter')
$resourceGroups = @(
    "rg-$ProjectName-$Environment-monitor",
    "rg-$ProjectName-$Environment-shared",
    "rg-$ProjectName-$Environment-workloads"
)

$policyAssignments = @(
    "pa-$ProjectName-$Environment-allowed-locations"
)
foreach ($tagName in $requiredTags) {
    $tagLower = $tagName.ToLowerInvariant()
    $policyAssignments += "pa-$ProjectName-$Environment-req-tag-$tagLower-res"
    $policyAssignments += "pa-$ProjectName-$Environment-req-tag-$tagLower-rg"
}

$diagName = "diag-$ProjectName-$Environment-sub-activity"
$budgetName = "bud-$ProjectName-$Environment"

Write-Step 'Delete subscription diagnostic setting'
if ($PSCmdlet.ShouldProcess($diagName, 'Delete diagnostic setting')) {
    Invoke-AzSafe -Arguments @(
        'rest', '--method', 'delete',
        '--url', "https://management.azure.com$($scope)/providers/Microsoft.Insights/diagnosticSettings/$($diagName)?api-version=2021-05-01-preview",
        '--only-show-errors'
    ) -IgnoreErrors | Out-Null
}

Write-Step 'Delete policy assignments'
foreach ($assignment in $policyAssignments) {
    if ($PSCmdlet.ShouldProcess($assignment, 'Delete policy assignment')) {
        Invoke-AzSafe -Arguments @(
            'policy', 'assignment', 'delete',
            '--name', $assignment,
            '--scope', $scope,
            '--only-show-errors'
        ) -IgnoreErrors | Out-Null
    }
}

Write-Step 'Delete subscription budget'
if ($PSCmdlet.ShouldProcess($budgetName, 'Delete subscription budget')) {
    Invoke-AzSafe -Arguments @(
        'rest', '--method', 'delete',
        '--url', "https://management.azure.com$($scope)/providers/Microsoft.Consumption/budgets/$($budgetName)?api-version=2024-08-01",
        '--only-show-errors'
    ) -IgnoreErrors | Out-Null
}

if ($RemoveRbac) {
    Write-Step 'Delete RBAC assignments for provided principals'
    foreach ($principalId in $PrincipalObjectIds) {
        if ([string]::IsNullOrWhiteSpace($principalId)) { continue }
        if ($PSCmdlet.ShouldProcess($principalId, 'Delete role assignments at subscription scope')) {
            $roleAssignmentsJson = Invoke-AzSafe -Arguments @(
                'role', 'assignment', 'list',
                '--assignee', $principalId,
                '--scope', $scope,
                '--only-show-errors',
                '--output', 'json'
            ) -IgnoreErrors

            if ($roleAssignmentsJson) {
                $roleAssignments = $roleAssignmentsJson | ConvertFrom-Json
                foreach ($ra in $roleAssignments) {
                    Invoke-AzSafe -Arguments @(
                        'role', 'assignment', 'delete',
                        '--ids', $ra.id,
                        '--only-show-errors'
                    ) -IgnoreErrors | Out-Null
                }
            }
        }
    }
}

Write-Step 'Delete resource groups'
foreach ($rgName in $resourceGroups) {
    $args = @('group', 'delete', '--name', $rgName, '--yes', '--only-show-errors')
    if ($NoWait) {
        $args += '--no-wait'
    }

    if ($PSCmdlet.ShouldProcess($rgName, 'Delete resource group')) {
        Invoke-AzSafe -Arguments $args -IgnoreErrors | Out-Null
    }
}

Write-Step 'Cleanup completed'
Invoke-AzSafe -Arguments @('group', 'list', '--query', "[?starts_with(name, 'rg-$ProjectName-$Environment-')].{name:name, location:location}", '--output', 'json') -OutFile (Join-Path $EvidencePath 'resource-groups-after-cleanup.json') -IgnoreErrors | Out-Null
Write-Host "Cleanup evidence saved to: $EvidencePath" -ForegroundColor Yellow
