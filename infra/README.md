# Azure Infrastructure for ZavaStorefront

## Architecture

All resources are provisioned into a single resource group (`rg-zavastore-dev-westus3`) in **West US 3**.

| Resource | Bicep Module | SKU | Purpose |
|---|---|---|---|
| Azure Container Registry | `modules/acr.bicep` | Basic | Store Docker images |
| App Service Plan (Linux) | `modules/appserviceplan.bicep` | B1 | Host the Web App |
| Web App for Containers | `modules/webapp.bicep` | — | Run the .NET app as a container |
| Application Insights + Log Analytics | `modules/appinsights.bicep` | PerGB2018 / Web | Monitoring & diagnostics |
| AI Foundry (Cognitive Services) | `modules/foundry.bicep` | S0 | GPT-4 & Phi-4 model access |
| AcrPull Role Assignment | `modules/roleassignment.bicep` | — | RBAC: Web App → ACR pull |

## Security

- **No admin credentials on ACR** — `adminUserEnabled: false`
- **Managed Identity** — Web App uses a system-assigned identity with `AcrPull` role to pull images from ACR
- **No password secrets** — all image pulls via Azure RBAC

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- An Azure subscription with sufficient quota for Cognitive Services in `westus3`

## Deployment

### Option 1: Azure Developer CLI (recommended)

```bash
# Login
azd auth login

# Initialize environment
azd init -e dev

# Provision infrastructure
azd provision

# Build and deploy (uses cloud build via ACR)
azd deploy
```

### Option 2: Azure CLI + Bicep directly

```bash
# Login
az login

# Deploy the Bicep template
az deployment sub create \
  --location westus3 \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam

# Build image in ACR (no local Docker needed)
az acr build \
  --registry <acr-name> \
  --image zavastore:latest \
  --file src/Dockerfile \
  src/

# Update Web App to use the image
az webapp config container set \
  --name <webapp-name> \
  --resource-group rg-zavastore-dev-westus3 \
  --container-image-name <acr>.azurecr.io/zavastore:latest
```

### Option 3: GitHub Actions (CI/CD)

The workflow at `.github/workflows/build-deploy.yml` automates provisioning, building, and deploying. Required secrets:

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | Service principal / app registration client ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription ID |

The workflow uses federated credentials (OIDC) — no client secrets needed.

## Cost Estimates (Dev)

| Resource | Estimated Monthly Cost |
|---|---|
| ACR Basic | ~$5 |
| App Service B1 | ~$13 |
| Log Analytics (30-day, PerGB) | ~$2-5 (low traffic) |
| Application Insights | Pay-per-use (minimal for dev) |
| AI Foundry S0 + model tokens | ~$0 base + pay-per-token |
| **Total** | **~$20-25/month** (low dev usage) |

## File Structure

```
infra/
├── main.bicep              # Orchestrator (subscription-scoped)
├── main.bicepparam         # Parameters file
└── modules/
    ├── acr.bicep           # Azure Container Registry
    ├── appinsights.bicep   # Application Insights + Log Analytics
    ├── appserviceplan.bicep# Linux App Service Plan
    ├── foundry.bicep       # AI Foundry + GPT-4 & Phi-4 deployments
    ├── roleassignment.bicep# AcrPull RBAC assignment
    └── webapp.bicep        # Web App for Containers
azure.yaml                  # AZD configuration
src/Dockerfile              # Multi-stage Docker build
.github/workflows/
└── build-deploy.yml        # CI/CD pipeline
```
