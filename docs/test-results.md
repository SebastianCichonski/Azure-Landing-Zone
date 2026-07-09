# Test Results – Azure Landing Zone

## 1. Cel dokumentu

Ten dokument opisuje wyniki testów walidacyjnych wykonanych po wdrożeniu projektu Azure Landing Zone.

Zakres testów odpowiada testom opisanym w `README.md`, w szczególności:

- Test 1: Brak wymaganych tagów
- Test 2: Wdrożenie w niedozwolonej lokalizacji
- Test 3: Poprawne wdrożenie zgodne z politykami
- Test 4: Weryfikacja logów w Log Analytics

Dodatkowo ujęto wyniki technicznej walidacji Bicep/ARM oraz wdrożenia przez skrypty PowerShell.

---

## 2. Informacje podstawowe

| Pole | Wartość |
|---|---|
| Projekt | Azure Landing Zone |
| Środowisko | dev |
| Region | westeurope |
| Data testów | `<data>` |
| Subskrypcja | `<subscription-id / masked>` |
| Commit | `<git commit hash>` |
| Osoba wykonująca | `<imię i nazwisko>` |

---

## 3. Podsumowanie testów

| ID | Test | Oczekiwany wynik | Wynik | Status |
|---|---|---|---|---|
| PRE-01 | Walidacja Bicep / ARM | Szablon przechodzi walidację | Walidacja zakończona poprawnie | PASS |
| PRE-02 | What-if | Zmiany zgodne z oczekiwaniami | Brak nieoczekiwanych zmian | PASS |
| DEP-01 | Deployment | Zasoby zostają wdrożone | Wdrożenie zakończone poprawnie | PASS |
| TST-01 | Brak tagów | Operacja zablokowana przez Azure Policy | Operacja odrzucona | PASS |
| TST-02 | Zła lokalizacja | Operacja zablokowana przez Azure Policy | Operacja odrzucona | PASS |
| TST-03 | Poprawne wdrożenie | Zasób utworzony poprawnie | Zasób został utworzony | PASS |
| TST-04 | Log Analytics / KQL | Widoczne zdarzenia w Log Analytics | Zdarzenia widoczne w wynikach KQL | PASS |

**Wynik końcowy:** PASS

---

## 4. Testy techniczne

### PRE-01 – Walidacja Bicep / ARM

**Opis:**  
Sprawdzenie poprawności składni Bicep oraz walidacja wdrożenia na poziomie subskrypcji.

**Komenda:**

```powershell
pwsh ./scripts/validate.ps1 -Location westeurope -ParamsFile ./infra/environments/dev.bicepparam
```

**Oczekiwany wynik:**  
Walidacja kończy się bez błędów.

**Wynik rzeczywisty:**  
`PASS`

**Dowód:**  
`evidence/validate-evidence/<pliki-lub-outputy-z-walidacji>`

---


### DEP-01 – Deployment

**Opis:**  
Wdrożenie Landing Zone przy użyciu skryptu `deploy.ps1`.

**Komenda:**

```powershell
pwsh ./scripts/deploy.ps1 -Location westeurope -ParamsFile ./infra/environments/dev.bicepparam
```

**Oczekiwany wynik:**  
Deployment kończy się powodzeniem.

**Wynik rzeczywisty:**  
`PASS`

**Dowód:**  
`evidence/deploy-evidence/<pliki-lub-outputy-deployment>`

---

## 5. Testy funkcjonalne z README.md

### TST-01 – Brak tagów

**Opis:**  
Próba utworzenia zasobu bez wymaganych tagów.

**Kroki testowe:**

1. Utworzono zasób bez tagów `Owner`, `Environment`, `CostCenter`.
2. Sprawdzono reakcję Azure Policy.

**Oczekiwany wynik:**  
Operacja zostaje zablokowana przez politykę `Require tag on resources`.

**Wynik rzeczywisty:**  
Operacja została odrzucona.

**Status:**  
`PASS`

**Dowód:**  
`evidence/screenshots/07-deny-missing-tags.png`

---

### TST-02 – Zła lokalizacja

**Opis:**  
Próba utworzenia zasobu w regionie innym niż `westeurope`.

**Kroki testowe:**

1. Wybrano niedozwolony region, np. `northeurope`.
2. Podjęto próbę utworzenia zasobu.
3. Sprawdzono reakcję Azure Policy.

**Oczekiwany wynik:**  
Operacja zostaje zablokowana przez politykę `Allowed locations`.

**Wynik rzeczywisty:**  
Operacja została odrzucona.

**Status:**  
`PASS`

**Dowód:**  
`evidence/screenshots/08-deny-wrong-location.png`

---

### TST-03 – Poprawne wdrożenie

**Opis:**  
Utworzenie zasobu zgodnego z wymaganiami Landing Zone.

**Kroki testowe:**

1. Wybrano dozwolony region `westeurope`.
2. Dodano wymagane tagi.
3. Utworzono zasób testowy.

**Oczekiwany wynik:**  
Zasób zostaje utworzony poprawnie.

**Wynik rzeczywisty:**  
Zasób został utworzony poprawnie.

**Status:**  
`PASS`

**Dowód:**  
`evidence/screenshots/09-success-with-tags.png`

---

### TST-04 – Log Analytics / KQL

**Opis:**  
Weryfikacja, czy Activity Log trafia do Log Analytics Workspace.

**Kroki testowe:**

1. Otworzono Log Analytics Workspace.
2. Uruchomiono zapytanie KQL dla `AzureActivity`.
3. Sprawdzono, czy widoczne są zdarzenia administracyjne.

**Przykładowe zapytanie:**

```kql
AzureActivity
| where TimeGenerated > ago(24h)
| sort by TimeGenerated desc
| take 50
```

**Oczekiwany wynik:**  
Widoczne są zdarzenia z Activity Log.

**Wynik rzeczywisty:**  
Zdarzenia są widoczne w Log Analytics.

**Status:**  
`PASS`

**Dowód:**  
`evidence/screenshots/04-kql-azureactivity.png`

---

## 6. Evidence Pack

| Plik | Powiązany test | Opis |
|---|---|---|
| `01-rbac-subscription.png` | DEP-01 | Role assignments na subskrypcji |
| `02-loganalytics-overview.png` | DEP-01 / TST-04 | Log Analytics Workspace |
| `03-activitylog-diagnostics.png` | TST-04 | Diagnostic settings: Activity Log → Log Analytics |
| `04-kql-azureactivity.png` | TST-04 | Wynik zapytania KQL |
| `05-policy-assignments.png` | TST-01 / TST-02 | Przypisane Azure Policy |
| `06-policy-compliance.png` | TST-01 / TST-02 | Compliance polityk |
| `07-deny-missing-tags.png` | TST-01 | Deny dla braku tagów |
| `08-deny-wrong-location.png` | TST-02 | Deny dla złego regionu |
| `09-success-with-tags.png` | TST-03 | Sukces dla poprawnego wdrożenia |
| `10-action-group.png` | DEP-01 | Action Group |
| `11-budgets.png` | DEP-01 | Budżet i progi alertów |

---

## 7. Znalezione problemy

| ID | Opis | Wpływ | Status |
|---|---|---|---|
| N/A | Nie wykryto błędów krytycznych | Brak | Zamknięte |

---

## 8. Wnioski

Testy potwierdzają, że projekt Azure Landing Zone działa zgodnie z założeniami opisanymi w `README.md`.

Zweryfikowano:

- poprawność wdrożenia Bicep,
- działanie Azure Policy dla tagów,
- działanie Azure Policy dla dozwolonych lokalizacji,
- możliwość poprawnego wdrożenia zasobu zgodnego z wymaganiami,
- przesyłanie Activity Log do Log Analytics,
- podstawowe elementy governance, RBAC, monitoringu i kontroli kosztów.

Środowisko można uznać za poprawnie wdrożone i gotowe do prezentacji jako projekt portfolio.

---


