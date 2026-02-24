# Naming standard

Ten dokument opisuje standard nazewnictwa dla repozytorium **Azure-Landing-Zone** (Landing Zone Lite).
Celem jest spójność nazw w kodzie (Bicep), w Azure Portal oraz w historii deploymentów.

---

## 1. Zasady ogólne

**Wymagania:**
- nazwy są deterministyczne (da się je przewidzieć bez szukania),
- spójny wzór w całym repo i w całym środowisku,
- brak spacji, polskich znaków,
- separator: `-` (kebab-case) dla zasobów,
- skróty tylko te z listy prefiksów (poniżej).

**Słownik pól we wzorcach:**
- `<project>` – skrót projektu (np. `alz`)
- `<env>` – środowisko: `dev | test | prod`
- `<tier>` – warstwa/obszar w subskrypcji: `monitor | shared | workloads`
- `<policy-key>` – krótki, opisowy identyfikator policy w `kebab-case`
- `<scope-key>` – identyfikator zakresu dla diagnostyki (np. `sub-activity`)

---

## 2. Nazwy Resource Groups (RG)

### Wzorzec
`rg-<project>-<env>-<tier>`

### Dozwolone wartości `<tier>`
- `monitor` – monitoring i alerting (Log Analytics, Action Group)
- `shared` – zasoby współdzielone (np. Key Vault, Managed Identity – jeśli używane)
- `workloads` – zasoby testowe / workloads (lab)

### Przykłady
- `rg-alz-dev-monitor`
- `rg-alz-dev-shared`
- `rg-alz-dev-workloads`

---

## 3. Nazwy zasobów platformowych (monitoring / cost / governance)

### 3.1 Log Analytics Workspace
**Wzorzec:** `law-<project>-<env>`  
**Przykłady:** `law-alz-dev`, `law-alz-prod`

### 3.2 Action Group
**Wzorzec:** `ag-<project>-<env>`  
**Przykłady:** `ag-alz-dev`, `ag-alz-prod`

### 3.3 Budget (Cost Management)
**Wzorzec:** `bud-<project>-<env>`  
**Przykłady:** `bud-alz-dev`, `bud-alz-prod`

### 3.4 Policy Assignment
**Wzorzec:** `pa-<project>-<env>-<policy-key>`  
**Zasady dla `<policy-key>`:**
- tylko `kebab-case`
- bez wielkich liter
- krótko i jednoznacznie

**Przykłady:**
- `pa-alz-dev-allowed-locations`
- `pa-alz-dev-req-tag-owner-res`
- `pa-alz-dev-req-tag-owner-rg`

### 3.5 Diagnostic Settings
**Wzorzec:** `diag-<project>-<env>-<scope-key>`  
**Przykłady:**
- `diag-alz-dev-sub-activity` (Activity Log na subskrypcji do Log Analytics)

---

## 4. Identity / RBAC (konwencje dokumentacyjne)

> Uwaga: obiektów Entra ID (grupy) nie tworzymy w Bicep.
> W repo utrzymujemy standard nazw w dokumentacji i opisach przypisań.

### 4.1 Grupy (Entra ID)
**Wzorzec:** `sg-<project>-<role>`  
**Przykłady:**
- `sg-alz-audit`
- `sg-alz-ops`
- `sg-alz-dev`

### 4.2 Przypisania ról (RBAC assignments)
Nazwy assignmentów nie zawsze są widoczne jak klasyczny zasób, ale dla spójności logiki:
- opisuj przypisania w kodzie/README jako:  
  `rbac:<group> -> <role(s)> @ <scope>`

**Przykład opisu:**
- `rbac: sg-alz-ops -> Monitoring Reader + Log Analytics Reader @ subscription`

---

## 5. Globalnie unikalne zasoby (na przyszłość)

Niektóre zasoby wymagają globalnej unikalności i/lub mają ograniczenia znaków:
- Storage Account (bez `-`, tylko małe litery i cyfry)
- ACR, niektóre DNS/endpointy

### Zalecany wzorzec (Storage Account)
`st<project><env><tier><suffix>`

Gdzie:
- `<suffix>` = 4–6 znaków z `uniqueString()` (deterministycznie)

**Przykład:**
- `stalzdevmon8f3c`

---

## 6. Nazwy w repo (Bicep modules, parametry, zmienne)

### 6.1 Pliki modułów (Bicep)
**Zasada:** nazwa pliku = „co tworzy”, bez projektu i env.  
**Format:** `camelCase` (spójnie z repo).

**Przykłady:**
- `resourceGroup.bicep`
- `logAnalytics.bicep`
- `diagnosticSettings.bicep`
- `policyAssignment.bicep`
- `rbac.bicep`
- `budget.bicep`

### 6.2 Instancje modułów w `main.bicep`
**Zasada:** `camelCase`, opisowo: `<obszar><Co><Gdzie>`.

**Przykłady:**
- `logAnalyticsMonitor`
- `actionGroupMonitor`
- `budgetSubscription`
- `diagSubscriptionActivityLogToLaw`
- `policyAllowedLocations`

### 6.3 Deployment `name:` w module
`name:` ma być krótkie i wskazywać obszar:
- `monitor-...`
- `governance-...`
- `iam-...`
- `cost-...`

**Przykłady:**
- `monitor-logAnalytics`
- `monitor-actionGroup`
- `cost-budget`
- `governance-pa-allowedLocations`

### 6.4 Parametry i zmienne
**Parametry:** `camelCase`, jednoznaczne domenowo.
- `projectName`, `environment`, `location`, `commonTags`
- `budgetAmount`, `budgetStartDate`, `budgetEndDate`
- `alertEmailAddresses`
- `activityLogCategories`

**Zmienne:** `camelCase`, z prefiksem typu obiektu:
- `rgMonitorName`, `rgSharedName`, `rgWorkloadsName`
- `laName`, `agName`

---

## 7. Checklist (code review)

Przy każdej zmianie IaC sprawdź:
- [ ] nowe zasoby mają poprawny prefix (rg/law/ag/bud/pa/diag/…)
- [ ] `<project>` i `<env>` są zawsze obecne
- [ ] `<tier>` jest jedną z wartości: monitor/shared/workloads
- [ ] policy-key i scope-key są w `kebab-case`
- [ ] globalnie unikalne zasoby mają suffix z `uniqueString()`
- [ ] instancje modułów i parametry są w `camelCase`

---

## 8. Examples from this repo

Poniższe przykłady pokazują, jak standard jest używany w praktyce w tym repozytorium.

### 8.1 Resource Groups (tiers)
W repo tworzysz trzy warstwy RG zgodnie z konwencją:

- `rg-<project>-<env>-monitor`
- `rg-<project>-<env>-shared`
- `rg-<project>-<env>-workloads`

Przykład (dev):
- `rg-alz-dev-monitor`
- `rg-alz-dev-shared`
- `rg-alz-dev-workloads`

### 8.2 Monitoring (Log Analytics + Action Group)
Przykładowe nazwy zasobów monitoringowych:

- Log Analytics Workspace: `law-<project>-<env>`  
  przykład: `law-alz-dev`

- Action Group: `ag-<project>-<env>`  
  przykład: `ag-alz-dev`

### 8.3 Cost management (Budget)
Budżet tworzony w standardzie:

- Budget: `bud-<project>-<env>`  
  przykład: `bud-alz-dev`

### 8.4 Governance (Policy assignments)
Policy assignmenty w repo mają postać:

- `pa-<project>-<env>-allowed-locations`
- `pa-<project>-<env>-req-tag-<tag>-res`
- `pa-<project>-<env>-req-tag-<tag>-rg`

Przykłady (tag `Owner`):
- `pa-alz-dev-req-tag-owner-res`
- `pa-alz-dev-req-tag-owner-rg`

### 8.5 Monitoring (Diagnostic settings)
Repo stosuje naming dla diagnostic settings, np. dla Activity Log na subskrypcji:

- `diag-<project>-<env>-sub-activity`  
  przykład: `diag-alz-dev-sub-activity`

### 8.6 IAM / RBAC (documented)
W repo (w dokumentacji i namingach logicznych) używamy wzorca:

- Entra group: `sg-<project>-<role>`

Przykłady:
- `sg-alz-audit`
- `sg-alz-ops`
- `sg-alz-dev`
  
  ### 8.7 Examples: module instance naming in `main.bicep`

Instancje modułów w `infra/main.bicep` nazywamy w `camelCase`, opisowo, według wzorca:

`<obszar><Co><Gdzie>`

Zasady:
- **obszar**: `monitor | governance | iam | cost | core`
- **Co**: typ zasobu (np. `LogAnalytics`, `ActionGroup`, `Budget`, `Policy`, `Diag`)
- **Gdzie**: zakres/warstwa (np. `Monitor`, `Subscription`, `Workloads`) lub cel (`ToLaw`)

Przykłady (zgodne z tym repo):
- `resourceGroups` – pętla tworząca RG (`rg-...-monitor/shared/workloads`)
- `logAnalyticsMonitor` – Log Analytics dla warstwy monitor
- `actionGroupMonitor` – Action Group dla alertów
- `budgetSubscription` – Budget na poziomie subskrypcji
- `diagSubscriptionActivityLogToLaw` – diagnostic settings: Activity Log → Log Analytics
- `policyAllowedLocations` – policy assignment: allowed locations
- `policyRequireTagsOnResources` – policy assignment: wymagane tagi na zasobach
- `policyRequireTagsOnResourceGroups` – policy assignment: wymagane tagi na RG

RBAC (IAM) – nazwy instancji modułów odpowiadają roli/zespołowi:
- `rbacOps` – przypisania dla `sg-alz-ops`
- `rbacAudit` – przypisania dla `sg-alz-audit`
- `rbacDev` – przypisania dla `sg-alz-dev`

> Wartość `name:` wewnątrz deklaracji modułu (deployment name) również trzymamy spójną i krótką, z prefiksem obszaru, np. `monitor-logAnalytics`, `cost-budget`, `governance-pa-allowedLocations`, `iam-rbac-ops`.