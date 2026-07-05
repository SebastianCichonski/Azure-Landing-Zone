<#
.SYNOPSIS
Deploys Azure Landing Zone at subscription scope.

.DESCRIPTION
Optionally runs validation first, then executes az deployment sub create and saves deployment output for evidence pack.
#>

[CmdletBinding()]
param(
    [string] $Location = 'westeurope',
    [string] $TemplateFile = './infra/main.bicep',
    [string] $ParamsFile = './infra/environments/dev.bicepparam',
    [string] $SubscriptionId = '',
    [string] $DeploymentName = "alz-deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss')",
    [switch] $SkipValidate,
    [string] $EvidencePath = "./evidence/deploy-evidence/deploy-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string] $Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Resolve-ExistingFile {
    param([string] $Path)
    $resolved = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
    if (-not $resolved) {
        throw "File not found: $Path"
    }
    return $resolved.Path
}

function Invoke-Az {
    param(
        [Parameter(Mandatory)] [string[]] $Arguments,
        [string] $OutFile = ''
    )

    Write-Host "az $($Arguments -join ' ')" -ForegroundColor DarkGray
    $output = & az @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    if ($OutFile) {
        $output | Out-File -FilePath $OutFile -Encoding utf8
    }

    if ($exitCode -ne 0) {
        $output | Write-Host -ForegroundColor Red
        throw "Azure CLI command failed with exit code $exitCode."
    }

    return $output
}

New-Item -ItemType Directory -Path $EvidencePath -Force | Out-Null
$TemplateFile = Resolve-ExistingFile $TemplateFile
$ParamsFile = Resolve-ExistingFile $ParamsFile

if ($SubscriptionId) {
    Write-Step 'Set subscription'
    Invoke-Az -Arguments @('account', 'set', '--subscription', $SubscriptionId, '--only-show-errors') | Out-Null
}

Write-Step 'Active subscription'
Invoke-Az -Arguments @('account', 'show', '--only-show-errors') -OutFile (Join-Path $EvidencePath 'account.json') | Out-Null

if (-not $SkipValidate) {
    Write-Step 'Pre-deployment validation'
    $validateScript = Join-Path $PSScriptRoot 'validate.ps1'
    & $validateScript `
        -Location $Location `
        -TemplateFile $TemplateFile `
        -ParamsFile $ParamsFile `
        -DeploymentName "validate-before-$DeploymentName" `
        -EvidencePath (Join-Path $EvidencePath 'pre-deploy-validation')
}

Write-Step 'Deploy Bicep at subscription scope'
Invoke-Az -Arguments @(
    'deployment', 'sub', 'create',
    '--name', $DeploymentName,
    '--location', $Location,
    '--parameters', $ParamsFile,
    '--only-show-errors',
    '--output', 'json'
) -OutFile (Join-Path $EvidencePath 'deployment-result.json') | Out-Null

Write-Step 'Deployment summary'
Invoke-Az -Arguments @(
    'deployment', 'sub', 'show',
    '--name', $DeploymentName,
    '--only-show-errors',
    '--output', 'json'
) -OutFile (Join-Path $EvidencePath 'deployment-show.json') | Out-Null

Write-Host "Deployment completed: $DeploymentName" -ForegroundColor Green
Write-Host "Evidence/log files saved to: $EvidencePath" -ForegroundColor Yellow
Write-Host "Next step: pwsh ./scripts/collect-evidence.ps1 -ProjectName alz -Environment dev" -ForegroundColor Yellow
