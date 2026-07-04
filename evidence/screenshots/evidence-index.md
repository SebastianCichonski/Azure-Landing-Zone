# Evidence Pack — Azure Landing Zone Lite

Zestaw zrzutów ekranu potwierdzających poprawne wdrożenie i działanie podstawowych elementów Azure Landing Zone. Dane wrażliwe, takie jak adres e-mail, identyfikatory subskrypcji, workspace ID oraz wybrane identyfikatory zasobów, zostały zanonimizowane.

|Plik|Obszar|Opis|
|-|-|-|
|`01-rbac-subscription.png`|RBAC|Przypisania ról na poziomie subskrypcji dla grup projektowych.|
|`02-loganalytics-overview.png`|Monitoring|Podgląd Log Analytics workspace z lokalizacją, modelem rozliczania i tagami.|
|`03-activitylog-diagnostics.png`|Monitoring|Ustawienie diagnostyczne Activity Log subskrypcji wysyłające logi do Log Analytics.|
|`04-kql-azureactivity.png`|Monitoring|Wynik zapytania KQL do tabeli `AzureActivity`, potwierdzający zbieranie logów aktywności subskrypcji.|
|`05-policy-assignments.png`|Governance|Przypisania Azure Policy wdrożone na poziomie subskrypcji.|
|`06-policy-compliance.png`|Governance|Stan zgodności polityk Landing Zone.|
|`07-deny-missing-tags.png`|Governance|Test blokady wdrożenia zasobu bez wymaganych tagów.|
|`08-deny-wrong-location.png`|Governance|Test blokady wdrożenia zasobu poza dozwolonym regionem Azure.|
|`09-success-with-tags.png`|Governance|Udane wdrożenie zasobu z wymaganymi tagami i w dozwolonym regionie.|
|`10-action-group.png`|Monitoring|Konfiguracja Action Group używanej do powiadomień budżetowych i monitoringowych.|
|`11-budgets.png`|Cost Management|Konfiguracja budżetu wraz z progami alertów.|
|`12-deployment-success.png`|IaC|Udane wdrożenia Bicep na poziomie subskrypcji.|
|`13-resource-groups-overview.png`|Governance|Struktura grup zasobów wdrożona w regionie West Europe.|

## Zakres evidence packa

Evidence pack potwierdza następujące obszary projektu:

* wdrożenie infrastruktury jako kodu przy użyciu Bicep,
* strukturę grup zasobów,
* przypisania RBAC na poziomie subskrypcji,
* konfigurację Log Analytics workspace,
* eksport Activity Log do Log Analytics,
* działanie zapytań KQL na danych z `AzureActivity`,
* przypisania i zgodność Azure Policy,
* blokowanie wdrożeń niezgodnych z politykami,
* poprawne wdrożenie zasobu spełniającego wymagania governance,
* konfigurację Action Group,
* konfigurację budżetu i progów alertów kosztowych.

