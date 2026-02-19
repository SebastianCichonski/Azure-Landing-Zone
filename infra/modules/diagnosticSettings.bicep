targetScope = 'subscription'

param diagName string 

param workspaceId string

param categories array

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
