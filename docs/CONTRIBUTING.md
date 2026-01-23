# CONTRIBUTING

Repozytorium jest projektem portfolio: **Azure Landing Zone** (governance + monitoring + kontrola kosztów + RBAC),
wdrażanym przez **Bicep** i obsługiwanym skryptami **PowerShell**.

Celem zasad jest spójność, czytelność zmian i łatwość oceny projektu (także przez rekruterów).

---

## 1) Polityka commitów (Conventional Commits)

Stosujemy uproszczony format:

```
<type>(<scope>): <temat>
```

Przykłady:
```
feat(policy): dodaj przypisania polityk tagowania
fix(bicep): popraw scope dla diagnostyki Activity Log
docs(readme): dodaj przykłady KQL i listę dowodów
```

### Dozwolone `type`
- **feat** — nowa funkcjonalność (nowy moduł, policy, zasób)
- **fix** — poprawka błędu (deployment failuje, zły scope, zły parametr)
- **docs** — tylko dokumentacja (README, decisions, diagrams, policies)
- **refactor** — przebudowa kodu bez zmiany działania (podział modułów, nazwy)
- **test** — testy / walidacje / scenariusze weryfikacji (validate.ps1, test plan)
- **chore** — porządki i utrzymanie repo (struktura, formatowanie, narzędzia)
- **ci** — zmiany w CI (jeśli dodasz GitHub Actions/Azure DevOps)
- **perf** — optymalizacje (np. ograniczenie log ingestion)
- **revert** — cofnięcie commita

### Dozwolone `scope` (użyj jednego)
Scope ma pokazać *którego obszaru dotyczy zmiana*.

Rekomendowane:
- **infra** — orkiestracja w `infra/main.bicep`
- **modules** — moduły w `infra/modules/`
- **policy** — Azure Policy (assignments/parametry)
- **rbac** — role assignments / model uprawnień
- **monitoring** — Log Analytics, diagnostyka, alerting
- **cost** — budżety, kontrola kosztów, retencja
- **scripts** — skrypty PowerShell w `scripts/`
- **docs** — pliki w `docs/` (diagramy, decyzje, testy, screeny)
- **readme** — zmiany w `README.md`
- **repo** — porządki w strukturze / pliki konfig.

Przykłady:
- `feat(monitoring): dodaj moduł log analytics workspace`
- `feat(cost): dodaj budżet subskrypcji z progami 50/80/100`
- `fix(policy): ustaw Deny dla allowed locations`
- `docs(docs): dodaj decisions i diagram architektury`

### Zasady tematu commita
- Tryb rozkazujący: **dodaj / zaktualizuj / usuń / popraw**
- Krótko i konkretnie (najlepiej **<= 72 znaki**)
- Bez kropki na końcu

### Breaking changes (opcjonalnie)
Jeśli zmiana jest “łamliwa” (np. zmieniasz nazwę parametru w `main.bicep`), dodaj `!`:
- `feat(infra)!: zmień nazwę parametru environment na env`

---

## 2) Nazewnictwo branchy

Stosuj:

```
<type>/<krótki-opis>
```

Przykłady:
- `feat/policy-tag-deny`
- `feat/monitoring-activitylog-to-la`
- `fix/bicep-scope`
- `docs/readme-evidence-pack`
- `chore/repo-structure`

---

## 3) Checklist PR / zmiany (nawet jeśli pracujesz solo)

### IaC (Bicep)
- [ ] `az bicep build` przechodzi (brak błędów składni)
- [ ] `az deployment sub what-if ...` działa
- [ ] Deployment jest idempotentny (ponowne uruchomienie nie psuje wdrożenia)
- [ ] Wszystkie zasoby mają tagi z obiektu `tags` (tam gdzie to ma sens)
- [ ] Nazwy zasobów zgodne z `docs/decisions.md`
- [ ] Scopes są poprawne (subscription vs resource group)

### Dokumentacja
- [ ] README odzwierciedla zmianę (zasoby/polityki/parametry)
- [ ] Jeśli decyzja architektoniczna się zmieniła → aktualizuj `docs/decisions.md`
- [ ] Jeśli zmieniono governance → aktualizuj `docs/policies.md`
- [ ] Jeśli zmiana wpływa na działanie “widoczne w portalu” → dodaj/aktualizuj screeny

### Koszty i higiena labu
- [ ] Diagnostyka i logi są minimalne (nie “zalewasz” LA)
- [ ] Retencja ustawiona sensownie (np. 30 dni)
- [ ] Dla nowych zasobów istnieje ścieżka sprzątania (`scripts/cleanup.ps1`)

---

## 4) Standardy kodu (Bicep)

### Zasady ogólne
- Preferuj **moduły** (RG, LA, Policy, RBAC, Budget)
- Jeden moduł = jedna logiczna funkcja
- Spójne parametry:
  - `location`, `projectName`, `environment`, `tags`
- Używaj `var` do nazw pochodnych (np. nazwy RG)
- Outputs tylko wtedy, gdy coś jest potrzebne dalej (np. `workspaceId`)

### Naming (zasoby)
Przykładowe wzorce:
- Resource Groups: `rg-<project>-<env>-<purpose>`
- Log Analytics: `law-<project>-<env>`
- Action Group: `ag-<project>-<env>`
- Budget: `bud-<project>-<env>`

### Format i czytelność
- Unikaj hardkodowania w modułach — przekazuj parametry
- Używaj `existing` jeśli potrzebujesz scope na istniejącym RG
- Trzymaj spójne wcięcia i porządek w plikach

---

## 5) Standardy skryptów (PowerShell)

- Skrypty muszą dać się uruchomić z repo root (albo jasno opisz wymagany katalog).
- `deploy.ps1` powinien:
  - sprawdzić logowanie (`az account show`)
  - wykonać deployment na **subscription scope**
- `validate.ps1` powinien:
  - uruchomić `what-if`
  - opcjonalnie wykonać podstawowe testy po wdrożeniu
- `cleanup.ps1` powinien:
  - usuwać zasoby pewnie (żeby nie generować kosztów)

---

## 6) Polityka “evidence pack” (screeny)

Wszystkie screeny trzymamy w:
- `docs/screenshots/`

Zasady:
- Numeruj rosnąco: `01-...`, `02-...`
- Screen ma pokazywać to, co istotne: scope, nazwy, przypisania, compliance
- Nigdy nie pokazuj sekretów (klucze/hasła/tokeny)

Rekomendowane dowody:
- Policy assignments + compliance
- Deny errors (brak tagów / zły region)
- Log Analytics + wynik KQL
- Diagnostic settings subskrypcji (Activity Log → LA)
- Budżet + konfiguracja alertów
- RBAC (role assignments na subskrypcji)

---

## 7) Krótka notatka “co/po co/jak sprawdzić”

Dla zmian wpływających na architekturę/governance dopisz (w opisie PR lub w body commita):
- **Co zmieniono?**
- **Dlaczego?**
- **Jak zweryfikować?**

Przykład:
- **Co:** tag policies przełączone z Audit na Deny  
- **Dlaczego:** wymuszenie guardrails governance  
- **Jak sprawdzić:** spróbuj utworzyć Storage bez tagów → oczekuj Deny
