@description('Name of the Azure Container Registry')
param name string

@description('Location for the resource')
param location string

@description('SKU for the Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('Tags to apply to the resource')
param tags object = {}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

@description('The resource ID of the ACR')
output id string = acr.id

@description('The login server of the ACR')
output loginServer string = acr.properties.loginServer

@description('The name of the ACR')
output name string = acr.name
