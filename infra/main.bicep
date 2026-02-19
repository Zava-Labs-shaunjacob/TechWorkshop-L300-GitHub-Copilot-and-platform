targetScope = 'subscription'

// ─── Parameters ─────────────────────────────────────────────────────────────

@description('Environment name (e.g. dev, staging, prod)')
param environmentName string

@description('Primary location for all resources')
param location string = 'westus3'

@description('SKU for Azure Container Registry')
param acrSku string = 'Basic'

@description('SKU for App Service Plan')
param appServicePlanSku string = 'B1'

@description('SKU for AI Foundry account')
param aiSku string = 'S0'

@description('Docker image and tag to deploy (leave empty for initial provisioning)')
param dockerImage string = ''

// ─── Variables ──────────────────────────────────────────────────────────────

var abbrs = {
  resourceGroup: 'rg-'
  containerRegistry: 'acr'
  appServicePlan: 'asp-'
  webApp: 'app-'
  appInsights: 'appi-'
  aiFoundry: 'ai-'
}

// Generate a short unique suffix to keep resource names within Azure limits
var uniqueSuffix = uniqueString(subscription().subscriptionId, environmentName, location)
var resourceToken = 'zavastore-${uniqueSuffix}'
var resourceGroupName = '${abbrs.resourceGroup}${resourceToken}'

// ACR: alphanumeric only, max 50 chars
var acrName = take('${abbrs.containerRegistry}zavastore${uniqueSuffix}', 50)
// App Service Plan: max 40 chars
var appServicePlanName = take('${abbrs.appServicePlan}${resourceToken}', 40)
// Web App: max 60 chars
var webAppName = take('${abbrs.webApp}${resourceToken}', 60)
// App Insights / Log Analytics workspace name: max 63 chars
var appInsightsName = take('${abbrs.appInsights}${resourceToken}', 63)
// AI Foundry: max 64 chars
var aiFoundryName = take('${abbrs.aiFoundry}${resourceToken}', 64)

var tags = {
  'azd-env-name': environmentName
  project: 'zavastore'
  environment: environmentName
}

// ─── Resource Group ─────────────────────────────────────────────────────────

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// ─── Modules ────────────────────────────────────────────────────────────────

module acr 'modules/acr.bicep' = {
  scope: rg
  params: {
    name: acrName
    location: location
    sku: acrSku
    tags: tags
  }
}

module appServicePlan 'modules/appserviceplan.bicep' = {
  scope: rg
  params: {
    name: appServicePlanName
    location: location
    skuName: appServicePlanSku
    tags: tags
  }
}

module appInsights 'modules/appinsights.bicep' = {
  scope: rg
  params: {
    name: appInsightsName
    location: location
    tags: tags
  }
}

module webApp 'modules/webapp.bicep' = {
  scope: rg
  params: {
    name: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    acrLoginServer: acr.outputs.loginServer
    dockerImage: dockerImage
    appInsightsConnectionString: appInsights.outputs.connectionString
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    tags: tags
  }
}

module acrPullRole 'modules/roleassignment.bicep' = {
  scope: rg
  params: {
    principalId: webApp.outputs.principalId
    acrName: acr.outputs.name
    principalType: 'ServicePrincipal'
  }
}

module foundry 'modules/foundry.bicep' = {
  scope: rg
  params: {
    name: aiFoundryName
    location: location
    skuName: aiSku
    tags: tags
  }
}

// ─── Outputs ────────────────────────────────────────────────────────────────

output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_ACR_NAME string = acr.outputs.name
output AZURE_ACR_LOGIN_SERVER string = acr.outputs.loginServer
output WEB_APP_NAME string = webApp.outputs.name
output WEB_APP_HOSTNAME string = webApp.outputs.defaultHostname
output AI_FOUNDRY_NAME string = foundry.outputs.name
output AI_FOUNDRY_ENDPOINT string = foundry.outputs.endpoint
