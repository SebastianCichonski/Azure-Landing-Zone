# Decisions — Landing Zone Lite (Azure)

Dokument opisuje kluczowe decyzje architektoniczne i operacyjne dla projektu **Landing Zone Lite**.
Celem jest stworzenie powtarzalnego fundamentu (governance + monitoring + cost controls + RBAC) pod wdrażanie workloadów w Azure.

---

## 1. Scope i cele

**Zakres:**
- Jedna subskrypcja Azure (lab)
- Konfiguracja “platform foundation”: RBAC, Azure Policy, centralne logowanie, kontrola kosztów
- Deploy w IaC (Bicep) + skrypty PowerShell (deploy/validate/cleanup)

**Poza zakresem (świadomie nie robione w Lite):**
- Management Groups (Enterprise-scale) i rozdział na wiele subskrypcji
- Pełny networking baseline (hub-spoke, firewall, vWAN) — będzie osobnym projektem
- SIEM/SOAR (Sentinel), Defender for Cloud “hardening” — osobny projekt

**Success criteria (Definition of Done):**
- Policy blokują tworzenie zasobów bez tagów i w niedozwolonych regionach
- Activity Log z subskrypcji trafia do Log Analytics i da się go przeszukać KQL
- RBAC działa w oparciu o grupy Entra (audyt ma tylko odczyt)
- Budżet i alerty kosztowe są ustawione
- Repo zawiera dokumentację, diagram i “evidence pack” (screenshots)

---

## 2. Naming i tagowanie

**Project code:** `lzlite`  
**Environment:** `dev`

**Standard nazw Resource Groups:**
- `rg-lzlite-dev-monitor`
- `rg-lzlite-dev-shared`
- `rg-lzlite-dev-workloads`

**Obowiązkowe tagi (minimum):**
- `Owner` = `<TwojeImięLubAlias>`
- `Environment` = `dev`
- `CostCenter` = `LAB`

**Uzasadnienie:**
- Tagi umożliwiają kosztowanie (chargeback), filtrowanie zasobów i automatyzację (policy/raporty).
- Spójne nazwy ułatwiają nawigację i operacje.

**Konsekwencje:**
- Zasoby bez tagów będą blokowane (Deny) po wdrożeniu governance.

---

## 3. Regiony i ograniczenia lokalizacji

**Dozwolone regiony:** `westeurope`  
**Policy:** Allowed locations (Deny)

**Uzasadnienie:**
- Ograniczenie regionów zmniejsza ryzyko przypadkowych kosztów i ułatwia zgodność (compliance).
- W labie wystarczy jeden region.

**Konsekwencje:**
- Próby wdrożeń w innych regionach będą odrzucane przez Azure Policy.

---

## 4. Struktura środowiska (RG split)

**Monitor RG (`rg-*-monitor`)**: Log Analytics Workspace, Action Group  
**Shared RG (`rg-*-shared`)**: zasoby wspólne (np. Key Vault w kolejnych projektach)  
**Workloads RG (`rg-*-workloads`)**: zasoby testowe do walidacji policy i logów

**Uzasadnienie:**
- Oddzielenie monitoringu od workloadów jest typowe dla “platform foundation”.
- Ułatwia sprzątanie labu i czytelność.

**Konsekwencje:**
- Monitoring jest centralny i nie “miesza się” z testowymi zasobami.

---

## 5. Identity & Access (RBAC)

**Model: RBAC przypisywany do grup Entra ID (nie do kont indywidualnych).**

**Grupy:**
- `sg-lz-ops` — operacje/utrzymanie
- `sg-lz-dev` — tworzenie zasobów (lab)
- `sg-lz-audit` — audyt/odczyt

**Role (scope: subscription):**
- `sg-lz-audit` → Reader
- `sg-lz-ops` → Monitoring Reader + Log Analytics Reader
- `sg-lz-dev` → Contributor

**Uzasadnienie:**
- Uprawnienia przez grupy są skalowalne i audytowalne.
- Rozdział ról odzwierciedla podstawowy podział odpowiedzialności.

**Konsekwencje / ryzyka:**
- Contributor dla dev w labie jest OK; w realnej firmie zwykle ogranicza się to dalej (np. przez custom roles i policy).

---

## 6. Governance (Azure Policy)

**Podejście:**
- Najpierw Audit (zobaczyć compliance), potem Deny (blokowanie).

**Polityki wdrażane w Lite:**
1) Allowed locations — `["westeurope"]` — **Deny**
2) Require tag on resources — `Owner`, `CostCenter` — **Deny**
3) Require tag on resource groups — `Owner`, `Environment`, `CostCenter` — **Deny**
4) (opcjonalnie) Require tag value — `Environment=dev` — **Deny/Audit** (zależnie od etapu)

**Uzasadnienie:**
- Minimalny zestaw guardrails wymuszający porządek i kontrolę.

**Konsekwencje:**
- Część “klików” w portalu przestanie działać bez tagów/poza regionem (celowo).

---

## 7. Monitoring & Logging

**Centralne logowanie:**
- Log Analytics Workspace (retention: `30` dni)
- Subscription Activity Log → Log Analytics (Diagnostic Settings)

**Uzasadnienie:**
- Umożliwia audyt zmian administracyjnych i zdarzeń policy.
- Daje podstawę pod alerting i operacje.

**Konsekwencje / koszty:**
- Koszt zależy od ingestowanych logów. W Lite zbieramy tylko Activity Log i ustawiamy krótką retencję.

---

## 8. Cost controls

**Budżet subskrypcji:** `<np. 15>`  
**Progi alertów:** 50% / 80% / 100%  
**Kanał powiadomień:** email (Action Group / bezpośrednio)

**Uzasadnienie:**
- Chroni lab przed “przypadkowym” zużyciem budżetu.
- Wymusza nawyk kontroli kosztów.

---

## 9. Infrastructure as Code i operacje

**IaC:** Bicep (main + moduły), deployment na scope subskrypcji  
**Skrypty:** PowerShell
- `deploy.ps1`
- `validate.ps1` (what-if + testy)
- `cleanup.ps1` (sprzątanie zasobów)

**Uzasadnienie:**
- Powtarzalność i możliwość weryfikacji zmian (what-if).
- Szybkie sprzątanie labu = mniejsze koszty.

---

## 10. Evidence pack (dowody)

Wymagane artefakty w `docs/screenshots/`:
- Policy assignments + compliance
- Deny error (missing tags, wrong location)
- Log Analytics + KQL results (AzureActivity)
- Subscription diagnostic settings (Activity Log → LA)
- Budget + Action Group
- Udzielone role RBAC na subskrypcji

---

## 11. Otwarte tematy / kolejne kroki

- Rozszerzenie do “Enterprise-scale”: Management Groups + kilka subskrypcji (platform / landing zones)
- Dołożenie network baseline (hub-spoke + private endpoints + DNS)
- Dołożenie bezpieczeństwa: Key Vault + Managed Identity + Defender / Sentinel (osobne projekty)
