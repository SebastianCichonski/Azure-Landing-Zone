<#
A. Pre-flight (zanim ruszysz IaC)
    Czy działa az i az bicep
    Czy jesteś zalogowany: az account show
    Jaka jest aktywna subskrypcja + opcjonalnie ustawienie --subscription
    Czy pliki istnieją: infra/main.bicep, plik parametrów
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

# Check login
try {
    $azaccount = az account show --only-show-errors | ConvertFrom-Json
}
catch {
    throw "Azure CLI is not logged in. Try: az login"
}
Write-Host ("Logged in. Subscryption: {0} ({1})" -f $azaccount.name, $azaccount.id)  -ForegroundColor DarkCyan

# Check bicep
try {
    $bicepVer = az bicep version --only-show-errors
}
catch {
    throw "Bicep is not available. Try: az bicep install"
}
Write-Host "Bicep version: $bicepVer" -ForegroundColor DarkCyan

Assert-File .\infra\main.bicep
Assert-Command az