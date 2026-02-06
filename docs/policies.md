# Azure Policy — Governance Baseline (Landing Zone Lite)

Ten dokument opisuje zestaw **Azure Policy** zastosowany w projekcie **Landing Zone Lite**: cele, przypisania, parametry,
zakres (scope), testy oraz evidence pack.

---

## 1) Cele governance

**Co chronimy / wymuszamy:**
- spójne tagowanie (koszty, właściciel, środowisko)
- kontrola lokalizacji (wdrożenia tylko w wybranych regionach)
- minimalne “guardrails” dla labu (łatwe do pokazania i przetestowania)

**Co jest poza zakresem wersji Lite (roadmap):**
- inicjatywy “enterprise scale” dla MG (management groups)
- złożone polityki security (Defender for Cloud, private endpoints only, itd.)
- automatyczne remediation (DeployIfNotExists) na dużą skalę

---

## 2) Scope i konwencje

**Scope przypisań:** `Subscription`  
**Uzasadnienie:** wersja Lite — prostsza demonstracja guardrails. W wersji “prod-like” część przypisań przejdzie na MG/RG.

**Nazewnictwo:**
- Assignment name: `pa-<project>-<env>-<short>`
- Initiative assignment (jeśli używasz): `pia-<project>-<env>-<short>`

**Non-compliance message:**
- Włączone (dla polityk Deny) z czytelnym komunikatem dla użytkownika.

---

## 3) Zestaw polityk (minimum w LZ Lite)

> Minimalny zestaw “portfolio friendly” — łatwy do wytłumaczenia i pokazania na screenach.

| ID/Typ | Nazwa (displayName) | Efekt | Scope | Parametry | Cel |
|-------|----------------------|-------|-------|----------|-----|
| Built-in | Allowed locations | Deny | Subscription | `listOfAllowedLocations=["westeurope"]` | blokada wdrożeń poza regionem |
| Built-in | Require a tag on resources | Deny | Subscription | `tagName="Owner"` | wymusza tag Owner |
| Built-in | Require a tag on resources | Deny | Subscription | `tagName="Environment"` | wymusza tag Environment |
| Built-in | Require a tag on resources | Deny | Subscription | `tagName="CostCenter"` | wymusza tag CostCenter |
| Built-in | Require a tag on resource groups | Deny | Subscription | `tagName="Owner"` | porządek tagów na RG |
| Built-in | Require a tag on resource groups | Deny | Subscription | `tagName="Environment"` | porządek tagów na RG |
| Built-in | Require a tag on resource groups | Deny | Subscription | `tagName="CostCenter"` | porządek tagów na RG |

**Opcjonalne (jeśli chcesz dodać „security wow effect”):**
| Built-in | Not allowed resource types | Deny | Subscription | np. public IP / wybrane resource types | ograniczenie “ryzykownych” zasobów w labie |
| Built-in | Audit VMs without managed disks | Audit | Subscription | - | przykład audytu bez blokowania |

---

## 4) Przypisania (assignments) — szczegóły

### 4.1 Allowed locations
- **Policy:** Allowed locations (built-in)
- **Effect:** Deny
- **Parametry:** `listOfAllowedLocations=["westeurope"]`
- **Non-compliance message:** `Deployments are restricted to West Europe.`
- **Uzasadnienie:** spójność, koszty, zgodność.

### 4.2 Require tags on resources (Owner/Environment/CostCenter)
- **Policy:** Require a tag on resources (built-in)
- **Effect:** Deny
- **Parametry:** `tagName="Owner"` / `"Environment"` / `"CostCenter"`
- **Non-compliance message:** np. `Missing required tag: Owner`
- **Uzasadnienie:** chargeback/showback, ownership, porządek.

### 4.3 Require tags on resource groups (Owner/Environment/CostCenter)
- **Policy:** Require a tag on resource groups (built-in)
- **Effect:** Deny
- **Parametry:** `tagName="Owner"` / `"Environment"` / `"CostCenter"`
- **Uzasadnienie:** porządek od samego początku.

---

## 5) Parametry i źródło prawdy

**Źródło prawdy dla wartości:** `infra/params/<env>.bicepparam`

Przykładowe wartości:
- `allowedLocations`: `["westeurope"]`
- wymagane tagi: `Owner`, `Environment`, `CostCenter`

---

## 6) Wyjątki / exemptions (opcjonalnie)

W wersji Lite zwykle brak exemptions.

Jeśli dodasz:
- **kiedy:** np. czasowe testy
- **zakres:** tylko konkretny RG
- **czas:** od-do
- **uzasadnienie:** dlaczego potrzebne

---

## 7) Testy walidacyjne (scenariusze)

### Test 1 — brak tagów (Deny)
**Kroki:**
1. Utwórz zasób (np. storage) bez tagów
2. Oczekiwany wynik: **Denied by policy**  
**Dowód:** `docs/screenshots/07-deny-missing-tags.png`

### Test 2 — zła lokalizacja (Deny)
**Kroki:**
1. Spróbuj wdrożyć zasób w innym regionie niż `westeurope`
2. Oczekiwany wynik: **Denied by policy**  
**Dowód:** `docs/screenshots/08-deny-wrong-location.png`

### Test 3 — poprawne wdrożenie (Allowed)
**Kroki:**
1. Utwórz zasób w `westeurope` z tagami Owner/Environment/CostCenter
2. Oczekiwany wynik: sukces  
**Dowód:** `docs/screenshots/09-success-with-tags.png`

---

## 8) Compliance i obserwacja

**Gdzie sprawdzać:**
- Azure Policy → **Assignments**
- Azure Policy → **Compliance**

**Oczekiwane zachowanie:**
- Polityki Deny blokują tworzenie zasobów niespełniających zasad
- Compliance pokazuje zasoby zgodne/niezgodne po ewaluacji

---

## 9) Evidence pack (screeny)

Zapisuj w `docs/screenshots/`:

- `05-policy-assignments.png` — lista przypisań (scope: subscription)
- `06-policy-compliance.png` — compliance
- `07-deny-missing-tags.png` — deny brak tagów
- `08-deny-wrong-location.png` — deny zły region
- `09-success-with-tags.png` — sukces wdrożenia zgodnego

---

## 10) Zmiany i wersjonowanie

**Zasada:** zmiany policy tylko przez IaC (Bicep), nie ręcznie w portalu.

Każda zmiana powinna mieć:
- commit `feat(policy): ...` lub `fix(policy): ...`
- aktualizację `docs/decisions.md` jeśli zmienia założenia governance
- aktualizację screenów, jeśli zmienia “dowody”

---

## 11) Troubleshooting (najczęstsze problemy)

- **Deny nie działa:** sprawdź scope assignmentu i efekt `Deny`
- **Compliance nie aktualne:** uruchom ponowną ewaluację lub poczekaj na cykl compliance
- **Zasób nie ma tagów mimo wymuszenia:** sprawdź czy policy jest na resources i/lub RG oraz czy deployment dodaje tagi w template
