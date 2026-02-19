using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'dev')
param location = readEnvironmentVariable('AZURE_LOCATION', 'westus3')
param acrSku = 'Basic'
param appServicePlanSku = 'B1'
param aiSku = 'S0'
param dockerImage = ''
