---

# 🚀 Azure Integration Deployment

This project provisions a full Azure environment for an integration solution using modular Bicep templates.  
It covers networking, application hosting, identity, secrets management, storage, IoT, monitoring, and messaging.

---

## 📦 Deployed Resources

### Networking
- **Virtual Network (VNet)** and multiple **Subnets**:
  - Default Subnet
  - Subnets for Service Bus, IoT Hub, Key Vault, Cosmos DB, Blob Storage
  - Subnets for Logic App Inbound and Outbound traffic
- **Private Endpoints**:
  - Storage Blob
  - Service Bus
  - Cosmos DB
  - Key Vault
  - IoT Hub
  - Logic App
- **Private DNS Zones**:
  - `privatelink.azurewebsites.net`
  - `privatelink.servicebus.windows.net`
  - `privatelink.blob.core.windows.net`
  - `privatelink.document.azure.com`
  - `privatelink.vaultcore.azure.net`
- **Private DNS Zone A Records** for resource private endpoints.

### Application Hosting
- **App Service Plan** (Workflow Standard SKU) for Logic App.
- **Logic App Standard**:
  - VNet Integrated
  - Private Endpoint enabled
  - Monitoring enabled (Application Insights)

### Storage
- **Storage Account** for Logic App storage needs.
- **File Share** for Logic App runtime content.

### Secrets Management
- **Azure Key Vault**:
  - Stores storage connection strings, service bus connection strings, Cosmos DB secrets.
  - Secured with private endpoint access.
  - Access control through managed identities.

### Messaging
- **Azure Service Bus Namespace**:
  - Topics (`customertransactions`) and Subscriptions (`customertransactionsubs`)
- **RBAC** configuration for Service Bus Topics.

### IoT
- **Azure IoT Hub**:
  - Message routing to Service Bus Topic.
  - Private endpoint integration.
  - Monitoring integrated.

### Monitoring
- **Log Analytics Workspace** for logs.
- **Application Insights** for monitoring application and IoT traffic.

---

## 🛠️ Bicep Modules Used

| Module | Purpose |
|:---|:---|
| `deployManagedIdentity.bicep` | Create Managed Identities |
| `deployAsp.bicep` | App Service Plan Deployment |
| `deployStorage.bicep` | Storage Account Creation |
| `deployFileShare.bicep` | File Share Setup |
| `deployLoggingAndMonitoring.bicep` | Log Analytics and Application Insights |
| `deployLogicAppStandard.bicep` | Logic App Standard Deployment |
| `deployKeyVault.bicep` | Key Vault Deployment |
| `deploySecrets.bicep` | Secrets in Key Vault |
| `deployServiceBus.bicep` | Service Bus Namespace, Topics, and Subscriptions |
| `deployCosmosDb.bicep` | Cosmos DB Account Setup |
| `deployIotHub.bicep` | IoT Hub Deployment and Message Routing |
| `deployPrivateEndPoint.bicep` | Private Endpoints for services |
| `deployPrivateDnsZoneARecord.bicep` | A records in Private DNS Zones |
| `deployKeyVaultSecret.bicep` | Key Vault Secrets |
| `deployConfigToLogicApp.bicep` | Configure Logic App Settings |

---

## 📋 Deployment Workflow

1. Provision Virtual Network and Subnets.
2. Deploy Managed Identities.
3. Set up Monitoring infrastructure.
4. Deploy Storage Account and File Share.
5. Deploy App Service Plan.
6. Deploy Logic App Standard.
7. Deploy Azure Key Vault.
8. Deploy Service Bus Namespace and Topics.
9. Deploy Cosmos DB Account.
10. Deploy IoT Hub with Routes.
11. Create Private Endpoints for all services.
12. Deploy DNS Zone A Records for Private Endpoints.
13. Store Secrets in Key Vault.
14. Final Configuration for Logic App.

---

## 🎯 Highlights

- **Secure**: Private endpoints for all critical services.
- **Automated**: Full deployment with modular Bicep templates.
- **Observability**: Centralized logging and monitoring using Log Analytics and Application Insights.
- **Scalable**: Supports extension to other services easily.
- **Secrets Management**: Secrets are never exposed and stored securely in Key Vault.

---

## 🧱 Prerequisites

- Azure CLI installed with Bicep support
- Access to an Azure subscription
- Permissions to deploy networking, identity, and resource providers
- All Bicep modules placed under the `/module/` folder
