targetScope = 'subscription'

@description('Name of the Budget.')
param budgetName string

@description('Action Group Id for notifications.')
param actionGroupId string

@minValue(1)
@description('Amount of Budget.')
param amount int

@description('Start date of Budget.')
param startDate string

@description('End date of Budget.')
param endDate string = ''

@allowed([
  'Monthly'
  'Quarterly'
  'Annually'
])
param timeGrain string = 'Monthly'

@allowed([
  'pl-pl'
  'en-us'
])
param locale string = 'pl-pl'

var timePeriod =empty(endDate) ? {startDate: startDate} : {startDate: startDate, endDate: endDate}

resource budget 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: budgetName
  properties: {
    amount: amount
    category: 'Cost'
    timeGrain: timeGrain
    timePeriod: timePeriod
    notifications:{
      actual50: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 50
        thresholdType: 'Actual'
        locale: locale
        contactGroups: [ actionGroupId ]
      }
      actual80: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 80
        thresholdType: 'Actual'
        locale: locale
        contactGroups: [ actionGroupId ]
      }
      actual100: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        thresholdType: 'Actual'
        locale: locale
        contactGroups: [ actionGroupId ]
      }
    }
  }
}
