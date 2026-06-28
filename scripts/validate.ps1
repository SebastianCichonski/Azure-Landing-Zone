<#
.SYNOPSIS
Validates Azure Landing Zone Bicep deployment.

.DESCRIPTION
Performs pre-flight checks, Bicep build, Bicep lint, ARM validation and optional what-if at subscription scope.
#>

[CmdletBinding()]
param(
    [string] $Location = 'westeurope',
    [string] $TemplateFile = './infra/main.bicep',
    [string] $ParamsFile = './infra/environments/dev.bicepparam',
    [string] $SubscriptionId = '',
    [string] $DeploymentName = "alz-validate-$(Get-Date -Format 'yyyyMMdd-HHmmss')",
    [switch] $SkipWhatIf,
    [string] $EvidencePath = "./evidence/$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"
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

function Assert-CommandExists {
    param([string] $Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $Name"
    }
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

Write-Step 'Pre-flight checks'
Assert-CommandExists 'az'

if ($SubscriptionId) {
    Invoke-Az -Arguments @('account', 'set', '--subscription', $SubscriptionId, '--only-show-errors') | Out-Null
}

$accountJson = Invoke-Az -Arguments @('account', 'show', '--only-show-errors') -OutFile (Join-Path $EvidencePath 'account.json')
$account = $accountJson | ConvertFrom-Json
Write-Host "Subscription: $($account.name) [$($account.id)]" -ForegroundColor Green

$bicepVersion = Invoke-Az -Arguments @('bicep', 'version', '--only-show-errors') -OutFile (Join-Path $EvidencePath 'bicep-version.txt')
Write-Host "Bicep: $bicepVersion" -ForegroundColor Green
Write-Host "Template: $TemplateFile" -ForegroundColor Green
Write-Host "Params:   $ParamsFile" -ForegroundColor Green

Write-Step 'Bicep build'
Invoke-Az -Arguments @('bicep', 'build', '--file', $TemplateFile, '--only-show-errors') -OutFile (Join-Path $EvidencePath 'bicep-build.txt') | Out-Null
Write-Host 'Bicep build OK' -ForegroundColor Green

Write-Step 'Bicep lint'
Invoke-Az -Arguments @('bicep', 'lint', '--file', $TemplateFile, '--only-show-errors') -OutFile (Join-Path $EvidencePath 'bicep-lint.txt') | Out-Null
Write-Host 'Bicep lint OK' -ForegroundColor Green

Write-Step 'ARM validation at subscription scope'
Invoke-Az -Arguments @(
    'deployment', 'sub', 'validate',
    '--name', $DeploymentName,
    '--location', $Location,
    '--parameters', $ParamsFile,
    '--only-show-errors'
) -OutFile (Join-Path $EvidencePath 'deployment-validate.json') | Out-Null
Write-Host 'Deployment validation OK' -ForegroundColor Green

if (-not $SkipWhatIf) {
    Write-Step 'What-if preview'
    Invoke-Az -Arguments @(
        'deployment', 'sub', 'what-if',
        '--name', $DeploymentName,
        '--location', $Location,
        '--parameters', $ParamsFile,
        '--result-format', 'ResourceIdOnly',
        '--only-show-errors'
    ) -OutFile (Join-Path $EvidencePath 'what-if.txt') | Out-Null
    Write-Host 'What-if completed' -ForegroundColor Green
}

Write-Step 'Validation completed'
Write-Host "Evidence/log files saved to: $EvidencePath" -ForegroundColor Yellow
