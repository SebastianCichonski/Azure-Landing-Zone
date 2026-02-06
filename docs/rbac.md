# RBAC (Role-Based Access Control) — Landing Zone Lite

Ten dokument opisuje model **Azure RBAC** wdrożony w projekcie **Landing Zone Lite**: grupy, role, scope, uzasadnienie
(least privilege), implementację w IaC oraz sposób weryfikacji (evidence pack).

> Uwaga: **grupy Microsoft Entra ID** nie są tworzone przez Bicep/ARM — w projekcie zakładamy, że powstają ręcznie
(ew. przez Microsoft Graph/Terraform), a do Bicep przekazujesz ich `objectId`.

---

## 1) Cele RBAC

- Rozdzielenie ról: **audit / ops / dev**
- Minimalizacja uprawnień (least privilege)
- Preferowane przypisania: **Group assignments** zamiast przypisań bezpośrednio do userów
- Prosta demonstracja na scope subskrypcji (wersja Lite)

---

## 2) Scope

**Docelowy scope przypisań:** `Subscription`

**Dlaczego subscription scope w wersji Lite?**
- szybciej i czytelniej do portfolio (jedno miejsce weryfikacji)
- mniej “szumu” w repo

**Prod-like (roadmap):**
- scope per RG (`rg-...-monitor`, `rg-...-workloads`)
- dodatkowe role niestandardowe (custom roles) dla węższych uprawnień

---

## 3) Grupy Entra ID

| Grupa | Opis | Kto należy |
|------|------|------------|
| `sg-lz-audit` | audyt/odczyt | osoby audytu / rekruter (read-only demo) |
| `sg-lz-ops` | monitoring i operacje | admin/ops |
| `sg-lz-dev` | wdrożenia w labie | dev/test |

**Wymagane dane wejściowe do IaC:**
- `objectId` dla każdej grupy (GUID)

**Jak zdobyć objectId (przykład):**
- Portal: Entra ID → Groups → wybierz grupę → **Object ID**
- CLI (opcjonalnie): `az ad group show --group "<displayName>" --query id -o tsv`

---

## 4) Mapowanie: grupa → role → scope

| Grupa | Rola (Azure RBAC) | Scope | Uzasadnienie |
|------|--------------------|-------|--------------|
| `sg-lz-audit` | Reader | Subscription | wgląd bez zmian |
| `sg-lz-ops` | Monitoring Reader | Subscription | wgląd w metryki/alerty |
| `sg-lz-ops` | Log Analytics Reader | Subscription | wykonywanie kwerend KQL |
| `sg-lz-dev` | Contributor | Subscription | wdrożenia w labie (ograniczone przez Policy Deny) |

---

## 5) Implementacja w IaC (Bicep)

### 5.1 Parametry
W `infra/params/<env>.bicepparam` trzymasz:
- `rbacAssignments`: lista przypisań (principalId + roleDefinitionGuid + principalType)

Przykład struktury (opisowo):
- `principalId`: objectId grupy Entra ID
- `roleDefinitionGuid`: GUID wbudowanej roli (np. Reader)
- `principalType`: `Group`

### 5.2 Moduł `rbac.bicep`
Moduł powinien tworzyć `Microsoft.Authorization/roleAssignments` na zadanym scope.

Dobre praktyki:
- obsługa **tablicy** przypisań (pętla)
- deterministyczne `name` (np. `guid(scope().id, principalId, roleDefinitionId)`)
- możliwość podania scope jako parametr (subscription / resourceGroup / managementGroup w przyszłości)

---

## 6) Weryfikacja (portal + CLI/PowerShell)

### 6.1 Portal
1. Subscription → **Access control (IAM)** → **Role assignments**
2. Filtr: `sg-lz-`
3. Sprawdź: role, scope = subscription, przypisania “Group”

### 6.2 Azure CLI
```bash
az role assignment list --scope /subscriptions/<SUB_ID> --query "[?principalType=='Group']"
```

### 6.3 PowerShell (Az)
```powershell
Get-AzRoleAssignment -Scope "/subscriptions/<SUB_ID>" | Where-Object {$_.ObjectType -eq "Group"}
```

---

## 7) Evidence pack (screeny)

Zapisuj w `docs/screenshots/`:

- `01-rbac-subscription.png` — subskrypcja → IAM → role assignments (grupy + role + scope)
- `02-rbac-sg-lz-ops.png` — szczegóły przypisania dla `sg-lz-ops`
- `03-rbac-sg-lz-dev.png` — szczegóły przypisania dla `sg-lz-dev`
- `04-rbac-sg-lz-audit.png` — szczegóły przypisania dla `sg-lz-audit`

---

## 8) Zasady operacyjne (rekomendacje)

- Role nadaje tylko właściciel subskrypcji (Owner / User Access Administrator)
- Przegląd co 30–90 dni: członkostwo w grupach + role assignments
- Dla produkcji: MFA + PIM (czasowe podnoszenie uprawnień) + break-glass account (odseparowane)

---

## 9) Najczęstsze problemy

- **Role assignment nie tworzy się:** brak uprawnień (potrzebujesz Owner lub User Access Administrator)
- **Błąd “principal not found”:** zły `objectId` grupy albo brak replikacji Entra ID (odczekaj chwilę)
- **Złe scope:** upewnij się, że deployment jest na subscription scope i `scope` w module jest prawidłowy
