
param budgetName string
param emails array
param amount int
param startDate string
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
        operator: 'GreaterThanOrEqualsTo'
        threshold: 50
        thresholdType: 'Actual'
        contactEmails: [ emails ]
      }
    }
  }
}
