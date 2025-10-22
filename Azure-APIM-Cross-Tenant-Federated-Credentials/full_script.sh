# tenant1 Variables
TENANT1_ID="your-tenant1-id"
TENANT1_SUBSCRIPTION="your-tenant1-subscription"
TENANT1_APIM_NAME="tenant1-apim"
TENANT1_RG="tenant1-rg"
UAMI_NAME="tenant1-uami"

# tenant2 Variables
TENANT2_ID="your-tenant2-id"
TENANT2_SUBSCRIPTION="your-tenant2-subscription"
TENANT2_APIM_NAME="tenant2-apim"
TENANT2_API_APP_NAME="tenant2-api-app"

# Step 1: Create the User-Assigned Managed Identity (tenant1)
az login --tenant $TENANT1_ID
az account set --subscription $TENANT1_SUBSCRIPTION

# Create UAMI if it doesn't exist
az identity show -g $TENANT1_RG -n $UAMI_NAME --query clientId -o tsv >/dev/null 2>&1 || \
az identity create -g $TENANT1_RG -n $UAMI_NAME -o none

# Get UAMI details
UAMI_JSON=$(az identity show -g $TENANT1_RG -n $UAMI_NAME -o json)
UAMI_CLIENT_ID=$(echo "$UAMI_JSON" | jq -r '.clientId')
UAMI_PRINCIPAL_ID=$(echo "$UAMI_JSON" | jq -r '.principalId')
UAMI_RESOURCE_ID=$(echo "$UAMI_JSON" | jq -r '.id')

echo "UAMI Client ID: $UAMI_CLIENT_ID"
echo "UAMI Principal ID (Object ID): $UAMI_PRINCIPAL_ID"

# Step 2: Attach UAMI to tenant1 APIM (tenant1)

az login --tenant $TENANT1_ID
az account set --subscription $TENANT1_SUBSCRIPTION

# Get APIM resource ID
APIM_RESOURCE_ID=$(az resource show \
  -g $TENANT1_RG \
  -n $TENANT1_APIM_NAME \
  --resource-type "Microsoft.ApiManagement/service" \
  --query id -o tsv)

# Attach UAMI to APIM
az resource update --ids "$APIM_RESOURCE_ID" \
  --set identity.type="UserAssigned" \
  --set identity.userAssignedIdentities."$UAMI_RESOURCE_ID"={} -o none

echo "Attached UAMI to APIM"

# Step 3: Create Multi-Tenant Bridge App (tenant1)
az login --tenant $TENANT1_ID
az account set --subscription $TENANT1_SUBSCRIPTION

# Create multi-tenant app registration
BRIDGE_APP_NAME="tenant1-bridge-app"
az ad app create \
  --display-name $BRIDGE_APP_NAME \
  --sign-in-audience AzureADMultipleOrgs

BRIDGE_APP_ID=$(az ad app list --display-name $BRIDGE_APP_NAME --query [0].appId -o tsv)
BRIDGE_APP_OBJECTID=$(az ad app list --display-name $BRIDGE_APP_NAME --query [0].id -o tsv)

echo "Bridge App ID (Client ID): $BRIDGE_APP_ID"
echo "Bridge App Object ID: $BRIDGE_APP_OBJECTID"

# Step 4: Create Service Principal in tenant2 (tenant2)
az login --tenant $TENANT2_ID
az account set --subscription $TENANT2_SUBSCRIPTION

# Create service principal for tenant1's bridge app in tenant2
TENANT1_SP_JSON=$(az ad sp create --id $BRIDGE_APP_ID -o json)
TENANT1_SP_OBJECTID=$(echo "$TENANT1_SP_JSON" | jq -r '.id')

echo "Created service principal in tenant2"
echo "tenant1 SP Object ID in tenant2: $TENANT1_SP_OBJECTID"

# Step 5: Configure Federated Credential (tenant2)
az login --tenant $TENANT1_ID

# Get the bridge app Object ID (not the App ID!)
BRIDGE_APP_OBJECTID=$(az ad app show --id $BRIDGE_APP_ID --query id -o tsv)

FED_CRED_NAME="APIM-UAMI-FederatedCred"

# Create federated credential using Microsoft Graph API
az rest --method POST \
  --uri "https://graph.microsoft.com/v1.0/applications/$BRIDGE_APP_OBJECTID/federatedIdentityCredentials" \
  --headers "Content-Type=application/json" \
  --body "{
    \"name\": \"$FED_CRED_NAME\",
    \"issuer\": \"https://login.microsoftonline.com/$TENANT1_ID/v2.0\",
    \"subject\": \"$UAMI_PRINCIPAL_ID\",
    \"description\": \"Allows APIM UAMI to request tokens for tenant2 API\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

echo "Created federated credential"

# Step 6: Create tenant2 API App with App Roles (tenant2)
az login --tenant $TENANT2_ID
az account set --subscription $TENANT2_SUBSCRIPTION

# Create the tenant2 API app registration
TENANT2_API_APP_NAME="tenant2-api-app"
TENANT2_API_JSON=$(az ad app create \
  --display-name $TENANT2_API_APP_NAME \
  --sign-in-audience "AzureADMyOrg" \
  -o json)
TENANT2_API_APPID=$(echo "$TENANT2_API_JSON" | jq -r '.appId')
TENANT2_API_OBJECTID=$(echo "$TENANT2_API_JSON" | jq -r '.id')

echo "Created tenant2 API app"
echo "tenant2 API App ID: $TENANT2_API_APPID"
echo "tenant2 API Object ID: $TENANT2_API_OBJECTID"

# Set identifier URI for the API
az ad app update --id $TENANT2_API_APPID --identifier-uris "api://$TENANT2_API_APPID"

# Define app role
APP_ROLE_ID=$(uuidgen)
APP_ROLE_VALUE="access_as_app"

# Add app role to tenant2 API app
az rest --method PATCH \
  --uri "https://graph.microsoft.com/v1.0/applications/$TENANT2_API_OBJECTID" \
  --headers "Content-Type=application/json" \
  --body "{
    \"appRoles\": [{
      \"allowedMemberTypes\": [\"Application\"],
      \"description\": \"Allow apps to call tenant2 API\",
      \"displayName\": \"Access tenant2 API\",
      \"id\": \"$APP_ROLE_ID\",
      \"isEnabled\": true,
      \"value\": \"$APP_ROLE_VALUE\"
    }]
  }"

echo  "Added app role to tenant2 API app"

# Create service principal for the tenant2 API app
TENANT2_API_SP_JSON=$(az ad sp create --id $TENANT2_API_APPID -o json)
TENANT2_API_SP_OBJECTID=$(echo "$TENANT2_API_SP_JSON" | jq -r '.id')

echo "Created service principal for tenant2 API app"
echo "tenant2 API SP Object ID: $TENANT2_API_SP_OBJECTID"

# Step 7: Assign App Role to tenant1 SP (tenant2)
# Still in tenant2 - assign app role to tenant1 SP
# This grants the tenant1 APIM permission to call the tenant2 API

az rest --method POST \
  --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$TENANT1_SP_OBJECTID/appRoleAssignments" \
  --headers "Content-Type=application/json" \
  --body "{
    \"principalId\": \"$TENANT1_SP_OBJECTID\",
    \"resourceId\": \"$TENANT2_API_SP_OBJECTID\",
    \"appRoleId\": \"$APP_ROLE_ID\"
  }"

echo "Assigned '$APP_ROLE_VALUE' role to tenant1 service principal"