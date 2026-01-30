<#
A. Pre-flight (zanim ruszysz IaC)
    +Czy działa az i az bicep
    +Czy jesteś zalogowany: az account show
    +Jaka jest aktywna subskrypcja + opcjonalnie ustawienie --subscription
    +Czy pliki istnieją: infra/main.bicep, plik parametrów
B. Walidacja Bicep/ARM
    az bicep build (wyłapie błędy składni Bicep)
    az deployment sub validate (sprawdza, czy deployment jest poprawny na subscription scope)
C. What-if
    az deployment sub what-if z opcją --result-format FullResourcePayloads (czytelniej w CI)
    Wyświetlenie podsumowania: liczba Create/Modify/Delete
D. Walidacja parametrów (minimalna, ale bardzo przydatna)
    tags.Owner, tags.Environment, tags.CostCenter muszą istnieć
    budgetAmount > 0
    budgetStartDate < budgetEndDate (i format ISO 8601)
    location niepusty (i najlepiej zgodny z allowed locations)
#>
$paramFilePath = ".\infra\environments\dev.bicepparam"
$bicepFilePath = ".\infra\main.bicep"

#========Functions==============
function Assert-File([string] $Path) {
    if(-not (Test-Path -Path $Path -PathType Leaf)) {
        throw "File not found: $Path"
    }
}

function Assert-Command([string] $Name) {
    if(-not(Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Missing required command: '$Name'. Install it and try again."
    }
}

#===========Pre-flight===================
Write-Host "===Pre-flight checks===" -ForegroundColor Yellow

# Check file
Assert-File $bicepFilePath
$bicepFile = Split-Path -Path $bicepFilePath -Leaf
Write-Host "`nBicep file checked:`t" -ForegroundColor Green -NoNewline
Write-Host "$bicepFile" -ForegroundColor Cyan

# Check file
Assert-File $paramFilePath
$paramFile = Split-Path -Path $paramFilePath -Leaf
Write-Host "Params file checked:`t" -ForegroundColor Green -NoNewline
Write-Host "$paramFile" -ForegroundColor Cyan

# Check extension
$ext = [IO.Path]::GetExtension($paramFilePath)
if($ext -ne ".bicepparam") {
    throw "This script expects '.bicepparam' file parameter."
}
Write-Host "Extension checked:`t" -ForegroundColor Green -NoNewline
Write-Host "$ext" -ForegroundColor Cyan

# Check login
try {
    $azaccount = az account show --only-show-errors | ConvertFrom-Json
}
catch {
    throw "Azure CLI is not logged in. Try: az login."
}
Write-Host "Subscryption checked:`t" -ForegroundColor Green -NoNewline
Write-Host "$($azaccount.name), $($azaccount.id)"  -ForegroundColor Cyan

# Check bicep
try {
    $bicepVer = az bicep version --only-show-errors
}
catch {
    throw "Bicep is not available. Try: az bicep install."
}
Write-Host "Bicep version checked:`t"-ForegroundColor Green -NoNewline
Write-Host "$bicepVer" -ForegroundColor Cyan

Write-Host "`n===Bicep/ARM validation===" -ForegroundColor Yellow

if (-not $SkipBicepBuild -and (Test-Path $TemplateFile)) {
  Write-Host "== Bicep build =="

  az bicep build --file $TemplateFile --only-show-errors | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Bicep build failed." } Write-Host "Bicep build OK."
} else {
  Write-Host "Skipping bicep build."
}

