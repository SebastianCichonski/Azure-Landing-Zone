# RBAC (Role-Based Access Control) — Azure Landing Zone

Ten dokument opisuje model **Azure RBAC** wdrożony w projekcie **Azure Landing Zone**: grupy, role, scope, uzasadnienie
(least privilege), implementację w IaC oraz sposób weryfikacji (evidence pack).

> Uwaga: **grupy Microsoft Entra ID** nie są tworzone przez Bicep/ARM — w projekcie zakładamy, że powstają ręcznie
(ew. przez Microsoft Graph/Terraform), a do Bicep przekazujesz ich `objectId`.

---

## 1) Cele RBAC

- Rozdzielenie ról: **audit / ops / dev**
- Minimalizacja uprawnień (least privilege)
- Preferowane przypisania: **Group assignments** zamiast przypisań bezpośrednio do userów
- Prosta demonstracja na scope subskrypcji

---

## 2) Scope

**Docelowy scope przypisań:** `Subscription`

**Dlaczego subscription scope w tej wersji?**
- szybciej i czytelniej do portfolio (jedno miejsce weryfikacji)


**Prod-like (roadmap):**
- scope per RG (`rg-...-monitor`, `rg-...-workloads`)
- dodatkowe role niestandardowe (custom roles) dla węższych uprawnień

---

## 3) Grupy Entra ID

| Grupa | Opis | Kto należy |
|------|------|------------|
| `sg-alz-audit` | audyt/odczyt | osoby audytu |
| `sg-alz-ops` | monitoring i operacje | admin/ops |
| `sg-alz-dev` | wdrożenia w labie | dev/test |

**Wymagane dane wejściowe do IaC:**
- `objectId` dla każdej grupy (GUID)

**Jak zdobyć objectId (przykład):**
- Portal: Entra ID → Groups → wybierz grupę → **Object ID**
- CLI (opcjonalnie): `az ad group show --group "<displayName>" --query id -o tsv`

---

## 4) Mapowanie: grupa → role → scope

| Grupa | Rola (Azure RBAC) | Scope | Uzasadnienie |
|------|--------------------|-------|--------------|
| `sg-alz-audit` | Reader | Subscription | wgląd bez zmian |
| `sg-alz-ops` | Monitoring Reader | Subscription | wgląd w metryki/alerty |
| `sg-alz-ops` | Log Analytics Reader | Subscription | wykonywanie kwerend KQL |
| `sg-alz-dev` | Contributor | Subscription | wdrożenia w labie (ograniczone przez Policy Deny) |

---

## 5) Implementacja w IaC (Bicep)

### 5.1 Parametry
W `infra/environments/dev.bicepparam` przekazywane są:
- `sgAuditId`, `sgOpsId`, `sgDevId` — Object ID grup Entra ID,
- `rolesAudit`, `rolesOps`, `rolesDev` — tablice GUID-ów ról Azure RBAC.

Moduł `rbac.bicep` tworzy role assignments w pętli dla każdej roli przypisanej do danej grupy.

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
2. Filtr: `sg-alz-`
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

Zapisuj w `evidence/screenshots/`:

- `01-rbac-subscription.png` — subskrypcja → IAM → role assignments (grupy + role + scope)


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
