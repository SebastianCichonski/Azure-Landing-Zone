# Azure Landing Zone — Deployment Guide

Ten dokument opisuje sposób walidacji, wdrożenia, zebrania evidence packa oraz cleanupu dla projektu **Azure Landing Zone**.

Projekt jest wdrażany jako **Infrastructure as Code** przy użyciu **Bicep** i skryptów **PowerShell** uruchamianych z katalogu głównego repozytorium.

---

## 1. Zakres wdrożenia

Wdrożenie wykonywane jest na poziomie **subskrypcji Azure**.

Główny plik Bicep:

```text
infra/main.bicep
```

Domyślny plik parametrów dla środowiska dev:

```text
infra/environments/dev.bicepparam
```

Skrypty pomocnicze:

```text
scripts/validate.ps1
scripts/deploy.ps1
scripts/collect-evidence.ps1
scripts/cleanup.ps1
```

Projekt wdraża bazową Landing Zone dla jednej subskrypcji Azure, obejmującą:

| Obszar | Co jest wdrażane |
|---|---|
| Resource Groups | `rg-<project>-<environment>-monitor`, `shared`, `workloads` |
| Monitoring | Log Analytics Workspace |
| Activity Log | Diagnostic Settings z poziomu subskrypcji do Log Analytics |
| Alerting | Action Group z odbiorcami mailowymi |
| Cost Management | Budget na poziomie subskrypcji |
| Governance | Azure Policy Assignments |
| RBAC | Role assignments dla grup Entra ID |

---

## 2. Wymagania wstępne

Przed uruchomieniem skryptów upewnij się, że masz:

1. **PowerShell 7+**

```powershell
pwsh --version
```

2. **Azure CLI**

```powershell
az version
```

3. **Dostęp do subskrypcji Azure**

```powershell
az login
az account show --output table
```

4. **Właściwą subskrypcję ustawioną jako aktywną**

```powershell
az account list --output table
az account set --subscription "<subscription-id>"
az account show --output table
```

5. **Uprawnienia do wdrożenia zasobów na poziomie subskrypcji**

Dla środowiska labowego najprościej użyć konta z rolą **Owner** na testowej subskrypcji. Projekt tworzy między innymi role assignments, policy assignments, budżet i diagnostic settings, więc zwykły Contributor może nie wystarczyć.

---

## 3. Struktura istotna dla deploymentu

```text
Azure-Landing-Zone/
├─ infra/
│  ├─ main.bicep
│  ├─ environments/
│  │  └─ dev.bicepparam
│  └─ modules/
│     ├─ actionGroup.bicep
│     ├─ budget.bicep
│     ├─ diagnosticSettings.bicep
│     ├─ logAnalytics.bicep
│     ├─ policyAssignments.bicep
│     ├─ rbac.bicep
│     └─ resourceGroup.bicep
├─ scripts/
│  ├─ validate.ps1
│  ├─ deploy.ps1
│  ├─ collect-evidence.ps1
│  └─ cleanup.ps1
└─ evidence/
```

Skrypty należy uruchamiać z katalogu głównego repozytorium, ponieważ domyślne ścieżki do plików są ścieżkami względnymi.

---

## 4. Parametry środowiska

Domyślna konfiguracja znajduje się w pliku:

```text
infra/environments/dev.bicepparam
```

Przed wdrożeniem sprawdź szczególnie:

| Parametr | Znaczenie |
|---|---|
| `projectName` | Krótka nazwa projektu, domyślnie `alz` |
| `environment` | Środowisko, domyślnie `dev` |
| `location` | Region Azure, domyślnie `westeurope` |
| `commonTags` | Tagi wymagane przez projekt |
| `budgetAmount` | Kwota budżetu |
| `budgetStartDate` | Data rozpoczęcia budżetu |
| `budgetEndDate` | Data zakończenia budżetu |
| `alertEmailAddresses` | Adresy e-mail do alertów kosztowych |
| `sgAuditId` | Object ID grupy audytowej |
| `sgOpsId` | Object ID grupy operacyjnej |
| `sgDevId` | Object ID grupy developerskiej |
| `rolesAudit` | Role przypisywane grupie audytowej |
| `rolesOps` | Role przypisywane grupie operacyjnej |
| `rolesDev` | Role przypisywane grupie developerskiej |
| `policyAllowedLocationsId` | ID polityki Allowed locations |
| `policyRequireTagOnResourcesId` | ID polityki Require tag on resources |
| `policyRequireTagOnRGId` | ID polityki Require tag on resource groups |
| `activityLogCategories` | Kategorie Activity Log wysyłane do Log Analytics |

Jeżeli wdrażasz projekt w innym tenantcie lub subskrypcji, wymień przede wszystkim:

```bicep
param sgAuditId = '<object-id-grupy-audit>'
param sgOpsId   = '<object-id-grupy-ops>'
param sgDevId   = '<object-id-grupy-dev>'
```

oraz adres e-mail:

```bicep
param alertEmailAddresses = [
  '<twoj-email@example.com>'
]
```

---

## 5. Logowanie i wybór subskrypcji

Zaloguj się do Azure:

```powershell
az login
```

Sprawdź dostępne subskrypcje:

```powershell
az account list --output table
```

Ustaw właściwą subskrypcję:

```powershell
az account set --subscription "<subscription-id>"
```

Sprawdź aktywny kontekst:

```powershell
az account show --output table
```

Alternatywnie możesz przekazać subskrypcję bezpośrednio do skryptów parametrem:

```powershell
-SubscriptionId "<subscription-id>"
```

---

## 6. Walidacja przed wdrożeniem

Walidację uruchom z katalogu głównego repozytorium:

```powershell
pwsh ./scripts/validate.ps1 `
  -Location westeurope `
  -ParamsFile ./infra/environments/dev.bicepparam
```

Możesz też jawnie wskazać subskrypcję:

```powershell
pwsh ./scripts/validate.ps1 `
  -Location westeurope `
  -ParamsFile ./infra/environments/dev.bicepparam `
  -SubscriptionId "<subscription-id>"
```

Skrypt `validate.ps1` wykonuje:

1. sprawdzenie, czy dostępna jest komenda `az`,
2. ustawienie subskrypcji, jeśli podano `-SubscriptionId`,
3. odczyt aktywnej subskrypcji,
4. sprawdzenie wersji Bicep,
5. `az bicep build`,
6. `az bicep lint`,
7. `az deployment sub validate`,
8. opcjonalnie `az deployment sub what-if`.

Domyślnie what-if jest wykonywany. Możesz go pominąć:

```powershell
pwsh ./scripts/validate.ps1 `
  -Location westeurope `
  -ParamsFile ./infra/environments/dev.bicepparam `
  -SkipWhatIf
```

Domyślny katalog evidence dla walidacji:

```text
evidence/validate-YYYY-MM-DD-HHMMSS/
```

Przykładowe pliki tworzone przez walidację:

```text
account.json
bicep-version.txt
bicep-build.txt
bicep-lint.txt
deployment-validate.json
what-if.txt
```

Jeżeli walidacja kończy się błędem, nie uruchamiaj deploymentu przed wyjaśnieniem przyczyny.

---

## 7. Wdrożenie

Po poprawnej walidacji uruchom deployment:

```powershell
pwsh ./scripts/deploy.ps1 `
  -Location westeurope `
  -ParamsFile ./infra/environments/dev.bicepparam
```

Z jawnym wskazaniem subskrypcji:

```powershell
pwsh ./scripts/deploy.ps1 `
  -Location westeurope `
  -ParamsFile ./infra/environments/dev.bicepparam `
  -SubscriptionId "<subscription-id>"
```

Skrypt `deploy.ps1` domyślnie uruchamia walidację przed wdrożeniem. Następnie wykonuje deployment na poziomie subskrypcji:

```powershell
az deployment sub create
```

Deployment korzysta z pliku:

```text
infra/environments/dev.bicepparam
```

Plik `dev.bicepparam` wskazuje główny template:

```bicep
using '../main.bicep'
```

Dlatego w skrypcie deploymentu przekazywany jest plik parametrów, a nie osobno `main.bicep`.

Jeżeli walidacja była już wykonana i świadomie chcesz ją pominąć, użyj:

```powershell
pwsh ./scripts/deploy.ps1 `
  -Location westeurope `
  -ParamsFile ./infra/environments/dev.bicepparam `
  -SkipValidate
```

Domyślny katalog evidence dla deploymentu:

```text
evidence/deploy-YYYY-MM-DD-HHMMSS/
```

Przykładowe pliki tworzone przez deployment:

```text
account.json
deployment-result.json
deployment-show.json
pre-deploy-validation/
```

---

## 8. Sprawdzenie po wdrożeniu

Po wdrożeniu możesz sprawdzić, czy zasoby zostały utworzone.

Resource Groups:

```powershell
az group list `
  --query "[?starts_with(name, 'rg-alz-dev-')].{name:name, location:location}" `
  --output table
```

Deploymenty na poziomie subskrypcji:

```powershell
az deployment sub list `
  --query "[?contains(name, 'alz')].{name:name, state:properties.provisioningState, timestamp:properties.timestamp}" `
  --output table
```

Policy assignments:

```powershell
$subId = az account show --query id -o tsv

az policy assignment list `
  --scope "/subscriptions/$subId" `
  --query "[?starts_with(name, 'pa-alz-dev-')].{name:name, displayName:displayName}" `
  --output table
```

Log Analytics Workspace:

```powershell
az monitor log-analytics workspace show `
  --resource-group rg-alz-dev-monitor `
  --workspace-name law-alz-dev `
  --output table
```

---

## 9. Zebranie evidence packa

Po wdrożeniu uruchom skrypt:

```powershell
pwsh ./scripts/collect-evidence.ps1 `
  -ProjectName alz `
  -Environment dev
```

Z jawnym wskazaniem subskrypcji:

```powershell
pwsh ./scripts/collect-evidence.ps1 `
  -ProjectName alz `
  -Environment dev `
  -SubscriptionId "<subscription-id>"
```

Domyślny katalog evidence:

```text
evidence/collect-evidence-YYYY-MM-DD-HHMMSS/
```

Skrypt zapisuje między innymi:

| Plik | Znaczenie |
|---|---|
| `01-subscription.json` | Aktywny kontekst subskrypcji |
| `02-subscription-deployments.json` | Deploymenty na poziomie subskrypcji |
| `03-resource-groups.json` | Resource Groupy projektu |
| `04-resources-by-project-tag.json` | Zasoby oznaczone tagiem projektu |
| `05-log-analytics-workspace.json` | Konfiguracja Log Analytics |
| `06-subscription-diagnostic-setting.json` | Diagnostic Settings dla Activity Log |
| `07-policy-assignments.json` | Policy assignments |
| `08-rbac-assignments-scope.json` | RBAC assignments widoczne na scope subskrypcji |
| `09-budget.json` | Budżet subskrypcji |
| `SUMMARY.md` | Krótkie podsumowanie evidence packa |

Przed publikacją evidence packa w repozytorium sprawdź, czy pliki nie zawierają danych, których nie chcesz pokazywać publicznie, na przykład pełnego Subscription ID, Tenant ID, Object ID, adresów e-mail lub nazw kont.

---

## 10. Cleanup

Cleanup usuwa zasoby labowe utworzone przez projekt.

Przed faktycznym usuwaniem warto użyć trybu `-WhatIf`:

```powershell
pwsh ./scripts/cleanup.ps1 `
  -ProjectName alz `
  -Environment dev `
  -WhatIf
```

Właściwe usuwanie:

```powershell
pwsh ./scripts/cleanup.ps1 `
  -ProjectName alz `
  -Environment dev
```

Cleanup z jawnym wskazaniem subskrypcji:

```powershell
pwsh ./scripts/cleanup.ps1 `
  -ProjectName alz `
  -Environment dev `
  -SubscriptionId "<subscription-id>"
```

Cleanup bez oczekiwania na zakończenie usuwania Resource Group:

```powershell
pwsh ./scripts/cleanup.ps1 `
  -ProjectName alz `
  -Environment dev `
  -NoWait
```

Skrypt `cleanup.ps1` usuwa:

1. Diagnostic Setting na poziomie subskrypcji:

```text
diag-alz-dev-sub-activity
```

2. Policy assignments:

```text
pa-alz-dev-allowed-locations
pa-alz-dev-req-tag-owner-res
pa-alz-dev-req-tag-environment-res
pa-alz-dev-req-tag-costcenter-res
pa-alz-dev-req-tag-owner-rg
pa-alz-dev-req-tag-environment-rg
pa-alz-dev-req-tag-costcenter-rg
```

3. Budget:

```text
bud-alz-dev
```

4. Resource Groups:

```text
rg-alz-dev-monitor
rg-alz-dev-shared
rg-alz-dev-workloads
```

RBAC nie jest usuwany domyślnie. Aby usunąć role assignments dla wskazanych principal IDs, użyj:

```powershell
pwsh ./scripts/cleanup.ps1 `
  -ProjectName alz `
  -Environment dev `
  -RemoveRbac `
  -PrincipalObjectIds "<sgAuditId>","<sgOpsId>","<sgDevId>"
```

Po cleanupie skrypt zapisuje evidence do katalogu:

```text
evidence/cleanup-YYYY-MM-DD-HHMMSS/
```

W tym między innymi:

```text
account-before-cleanup.json
resource-groups-after-cleanup.json
```

---

## 11. Typowy przebieg pracy

Rekomendowana kolejność:

```powershell
# 1. Logowanie
az login
az account set --subscription "<subscription-id>"

# 2. Walidacja
pwsh ./scripts/validate.ps1 `
  -Location westeurope `
  -ParamsFile ./infra/environments/dev.bicepparam

# 3. Deployment
pwsh ./scripts/deploy.ps1 `
  -Location westeurope `
  -ParamsFile ./infra/environments/dev.bicepparam

# 4. Evidence pack
pwsh ./scripts/collect-evidence.ps1 `
  -ProjectName alz `
  -Environment dev

# 5. Cleanup po zakończeniu testów
pwsh ./scripts/cleanup.ps1 `
  -ProjectName alz `
  -Environment dev
```

---

## 12. Najczęstsze problemy

### Błąd: `File not found`

Sprawdź, czy uruchamiasz skrypt z katalogu głównego repozytorium.

Poprawna ścieżka do parametrów:

```text
./infra/environments/dev.bicepparam
```

Niepoprawne przykłady:

```text
./infra/environment/dev.bicepparam
./infra/environments/dev.bicepparaam
```

---

### Błąd: `InteractionRequired`

Najczęściej oznacza, że Azure CLI wymaga ponownego logowania, MFA albo odświeżenia sesji.

Spróbuj:

```powershell
az logout
az login
az account set --subscription "<subscription-id>"
```

Jeżeli standardowe logowanie nie działa, użyj device code:

```powershell
az login --use-device-code
```

---

### Błąd: `AuthorizationFailed`

Konto nie ma wystarczających uprawnień do wdrażania zasobów na poziomie subskrypcji.

Sprawdź:

```powershell
az role assignment list `
  --assignee "<your-user-or-object-id>" `
  --all `
  --output table
```

Dla tego labu najprościej użyć testowej subskrypcji, gdzie konto wdrażające ma rolę **Owner**.

---

### Błąd przy RBAC

Sprawdź, czy w `dev.bicepparam` podano poprawne Object ID grup Entra ID:

```bicep
param sgAuditId = '<object-id>'
param sgOpsId   = '<object-id>'
param sgDevId   = '<object-id>'
```

Możesz sprawdzić grupy komendą:

```powershell
az ad group list `
  --query "[].{displayName:displayName, id:id}" `
  --output table
```

---

### Błąd przy Policy Assignment

Sprawdź, czy ID polityk w pliku parametrów są poprawne:

```bicep
param policyAllowedLocationsId = '<policy-definition-id>'
param policyRequireTagOnResourcesId = '<policy-definition-id>'
param policyRequireTagOnRGId = '<policy-definition-id>'
```

Jeżeli zmieniasz politykę, upewnij się, że jej parametry w `main.bicep` odpowiadają temu, czego oczekuje dana definicja policy.

---

### What-if pokazuje zmiany, których się nie spodziewasz

Nie wdrażaj automatycznie. Najpierw sprawdź plik:

```text
evidence/validate-*/what-if.txt
```

What-if powinien być potraktowany jako przegląd zmian przed deploymentem.

---

## 13. Uwagi dla portfolio

Ten projekt dobrze pokazuje podstawowe elementy Landing Zone:

- Infrastructure as Code z Bicep,
- deployment na scope subskrypcji,
- modularizację Bicep,
- Azure Policy jako guardrails,
- RBAC dla grup Entra ID,
- centralne logowanie Activity Log do Log Analytics,
- budżet i alerty kosztowe,
- walidację przed wdrożeniem,
- evidence pack po wdrożeniu,
- cleanup po zakończeniu testów.

Do portfolio warto dołączyć:

```text
evidence/collect-evidence-*/SUMMARY.md
docs/screenshots/
docs/test-results.md
docs/iam.md
docs/policies.md
```

Przed publikacją usuń lub zamaskuj dane wrażliwe.
