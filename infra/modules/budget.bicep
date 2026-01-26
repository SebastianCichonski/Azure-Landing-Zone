targetScope = 'subscription'

@description('Name of the budget.')
param budgetName string

@description('Action Group Id for notifications.')
param actionGroupId string

@description('Amount of budget.')
param amount int

@description('Start date of budget.')
param startDate string

@description('End date of budget.')
param endDate string = ''

var timePeriod =empty(endDate) ? {startDate: startDate} : {startDate: startDate, endDate: endDate}

resource budget 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: budgetName
  properties: {
    amount: amount
    category: 'Cost'
    timeGrain: 'Monthly'
    timePeriod: timePeriod
    notifications:{
      actual50: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 50
        thresholdType: 'Actual'
        contactGroups: [ actionGroupId ]
      }
      actual80: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 80
        thresholdType: 'Actual'
        contactGroups: [ actionGroupId ]
      }
      actual100: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        thresholdType: 'Actual'
        contactGroups: [ actionGroupId ]
      }
    }
  }
}
