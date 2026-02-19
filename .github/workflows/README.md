# Deployment Setup

The `build-deploy.yml` workflow builds the container image in ACR and deploys it to Azure App Service on every push to `main`. It uses **OpenID Connect (OIDC) federated credentials** — no long-lived secrets are stored in GitHub.

## Prerequisites

1. Infrastructure provisioned via the `infra/` Bicep templates (ACR, App Service, etc.).
2. An Entra ID app registration with a federated credential for GitHub Actions.

## 1. Create an Entra ID app registration and federated credential

```bash
# Create the app registration
az ad app create --display-name github-deploy
APP_ID=$(az ad app list --display-name github-deploy --query "[0].appId" -o tsv)

# Create a service principal
az ad sp create --id $APP_ID

# Assign Contributor on the resource group and AcrPush on the registry
az role assignment create --assignee $APP_ID --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>
az role assignment create --assignee $APP_ID --role AcrPush \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.ContainerRegistry/registries/<ACR_NAME>

# Add the OIDC federated credential for the main branch
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "github-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<OWNER>/<REPO>:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

## 2. GitHub Secrets

Go to **Settings > Secrets and variables > Actions > Secrets** and add:

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | App registration Application (client) ID |
| `AZURE_TENANT_ID` | Microsoft Entra tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

## 3. GitHub Variables

Go to **Settings > Secrets and variables > Actions > Variables** and add:

| Variable | Example | Description |
|---|---|---|
| `AZURE_ACR_NAME` | `acrzavastoreabc123` | ACR resource name |
| `AZURE_ACR_LOGIN_SERVER` | `acrzavastoreabc123.azurecr.io` | ACR login server FQDN |
| `WEB_APP_NAME` | `app-zavastore-abc123` | App Service resource name |

Get actual values from your deployment outputs:

```bash
azd env get-values
# or
az deployment sub show -n main --query properties.outputs
```
