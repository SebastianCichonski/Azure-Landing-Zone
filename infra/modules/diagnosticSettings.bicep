targetScope = 'subscription'

@description('Diagnostic Settings name.')
param diagName string 

@description('Log Analytic Workspaces ID.')
param workspaceId string

type ActivityLogCategory =  'Administrative'
| 'Security'
| 'ServiceHealth'
| 'Alert'
| 'Recommendation'
| 'Policy'
| 'Autoscale'
| 'ResourceHealth'

@description('Category of Activity Log.')
param categories ActivityLogCategory[]

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
        metrics: []
    }

}
