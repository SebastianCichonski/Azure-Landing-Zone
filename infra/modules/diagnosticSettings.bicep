targetScope = 'subscription'

@description('Diagnostic Settings name')
param diagName string 

@description('Log Analytic Workspaces ID')
param workspaceId string

@description('Category of Activity Log')
@allowed([
    'Administrative'
    'Security'
    'ServiceHealth'
    'Alert'
    'Recomendation'
    'Policy'
    'Autoscale'
    'ResourceHealth'
])
param categories string[]

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
    name: diagName
    scope: subscription()
    properties: {
        workspaceId: workspaceId
        logs: [ 
            for category in categories: { 
                category: category
                enabled: true
            }
        ]
    }

}
