@description('Name of the AI Foundry account')
param name string

@description('Location for the resource')
param location string

@description('SKU name for the AI Foundry account')
param skuName string = 'S0'

@description('Tags to apply to the resource')
param tags object = {}

resource aiAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiAccount
  name: 'gpt-4o'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-08-06'
    }
    raiPolicyName: 'Microsoft.DefaultV2'
  }
}

@description('The resource ID of the AI Foundry account')
output id string = aiAccount.id

@description('The endpoint of the AI Foundry account')
output endpoint string = aiAccount.properties.endpoint

@description('The name of the AI Foundry account')
output name string = aiAccount.name
