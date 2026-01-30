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
$location = "westeurope"

#========Functions==============
function Assert-File([string] $Path) {
    if(-not (Test-Path -Path $Path -PathType Leaf)) {
        return 0
    }
    return 1
}

function Assert-Command([string] $Name) {
    if(-not(Get-Command $Name -ErrorAction SilentlyContinue)) {
        return 0
    }
    return 1
}

#===========Pre-flight===================
Write-Host "=== Pre-flight checks ===" -ForegroundColor Yellow

# Check file
Write-Host "Bicep file checked:`t" -ForegroundColor Green -NoNewline
if(Assert-File $bicepFilePath) {
    $bicepFile = Split-Path -Path $bicepFilePath -Leaf
    Write-Host "$bicepFile" -ForegroundColor Cyan
} 
else {
    Write-Host "FAIL." -ForegroundColor Red
}

# Check file
Write-Host "Params file checked:`t" -ForegroundColor Green -NoNewline
if(Assert-File $paramFilePath) {
    $paramFile = Split-Path -Path $paramFilePath -Leaf
    Write-Host "$paramFile" -ForegroundColor Cyan
}
else {
    Write-Host "FAIL." -ForegroundColor Red
}

# Check az
Write-Host "az command checked:`t" -ForegroundColor Green -NoNewline
if(Assert-Command "az") {
    Write-Host "OK." -ForegroundColor Cyan
}
else {
    Write-Host "FAIL." -ForegroundColor Red
}

# Check extension
Write-Host "Extension checked:`t" -ForegroundColor Green -NoNewline
$ext = [IO.Path]::GetExtension($paramFilePath)
if($ext -ne ".bicepparam") {
    Write-Host "FAIL." -ForegroundColor Red
}
else {
    Write-Host "$ext" -ForegroundColor Cyan
}

# Check login
Write-Host "Subscription checked:`t" -ForegroundColor Green -NoNewline
$azaccount = az account show --only-show-errors | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { 
    Write-Host "FAILED." -ForegroundColor Red 
}    
else { 
    Write-Host "$($azaccount.name), $($azaccount.id)"  -ForegroundColor Cyan 
}

# Check bicep
Write-Host "Bicep version checked:`t"-ForegroundColor Green -NoNewline
$bicepVer = az bicep version --only-show-errors
if ($LASTEXITCODE -ne 0) { 
    Write-Host "FAILED." -ForegroundColor Red 
}    
else { 
    Write-Host "$bicepVer" -ForegroundColor Cyan
}

#==========Bicep/ARM validation=============

Write-Host "`n=== Bicep/ARM validation ===" -ForegroundColor Yellow

# Bicep build validation
Write-Host "Bicep build:`t" -ForegroundColor Green -NoNewline

az bicep build `
 --file $bicepFilePath `
 --only-show-errors | Out-Null

if ($LASTEXITCODE -ne 0) { 
    Write-Host "FAILED." -ForegroundColor Red 
} 
else {
    Write-Host "OK." -ForegroundColor Cyan
}

# Bicep lint
Write-Host "Bicep lint:`t" -ForegroundColor Green -NoNewline

az bicep lint `
    --file $bicepFilePath `
    --only-show-errors | Out-Null

if ($LASTEXITCODE -ne 0) { 
    Write-Host "FAILED." -ForegroundColor Red
}
else { 
    Write-Host "OK." -ForegroundColor Cyan 
}

# ARM validate (subscription scope)
Write-Host "Deployment validate:`t" -ForegroundColor Green -NoNewline

az deployment sub validate `
    --location $location `
    --parameters $paramFilePath `
    --only-show-errors | Out-Null

if ($LASTEXITCODE -ne 0) { 
    Write-Host "FAILED." -ForegroundColor Red 
}
else {
    Write-Host "OK." -ForegroundColor Cyan
} 

#==========What-if validation=============

Write-Host "`n=== What-if ===" -ForegroundColor Yellow
Write-Host "What-if:`t" -ForegroundColor Green -NoNewline

$whatIf = az deployment sub what-if `
      --location $location `
      --parameters $paramFilePath `
      --result-format ResourceIdOnly `
      --only-show-errors

if ($LASTEXITCODE -ne 0) { 
    Write-Host "FAILED." -ForegroundColor Red 
}
else {
    Write-Host $whatIf[-1] -ForegroundColor Cyan
}
