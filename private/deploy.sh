export UUID_SHORT=$(uuidgen | cut -c1-4 | tr '[:upper:]' '[:lower:]')
export RESOURCE_GROUP="privateaca-${UUID_SHORT}"
export FRONTDOOR_RESOURCE_GROUP="$RESOURCE_GROUP"
export API_NAME="api${UUID_SHORT}"
export LOCATION="germanywestcentral"
export CONTAINERAPPS_ENVIRONMENT="aca-${UUID_SHORT}"
export VNET_NAME="aca-${UUID_SHORT}-vnet"
export MANAGED_RG="$RESOURCE_GROUP-managed"
export LOG_ANALYTICS_WORKSPACE_NAME="ala-${UUID_SHORT}"
echo $RESOURCE_GROUP $LOCATION $CONTAINERAPPS_ENVIRONMENT $VNET_NAME 



export FRONTDOOR_PROFILE_NAME="frontdoor-$UUID_SHORT"
export FRONTDOOR_ORIGIN_GROUP_NAME="default-origin-group"
export FRONTDOOR_ENDPOINT_NAME="default-endpoint$UUID_SHORT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_in_color() {
    local color=$1
    local text=$2
    echo  "${color}${text}${NC}"
}

print_in_color "$YELLOW" "Create a resource group"
az group create --name $RESOURCE_GROUP --location $LOCATION
##//create a log analytics workspace
print_in_color "$YELLOW" "Create a log analytics workspace"
az monitor log-analytics workspace create --resource-group $RESOURCE_GROUP --workspace-name $RESOURCE_GROUP --location $LOCATION
print_in_color "$YELLOW" "Create a frontdoor profile"
az afd profile create \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --sku Premium_AzureFrontDoor  
## configure the log analytics workspace
print_in_color "$YELLOW" "Configure the log analytics workspace diagnostic settings"
az monitor diagnostic-settings update \
    --name "default" \
    --resource $FRONTDOOR_PROFILE_NAME \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --workspace $LOG_ANALYTICS_WORKSPACE_NAME \
    --logs '[
        {
            "category": "FrontdoorAccessLog",
            "enabled": true,
            "retentionPolicy": {
                "days": 0,
                "enabled": false
            }
        },
        {
            "category": "FrontdoorWebApplicationFirewallLog",
            "enabled": true,
            "retentionPolicy": {
                "days": 0,
                "enabled": false
            }
        }
    ]' \
    --metrics '[]'

print_in_color "$YELLOW" " Create an endpoint. An endpoint is the entry point for your application. It is the URL that you use to access your application."
az afd endpoint create \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --endpoint-name $FRONTDOOR_ENDPOINT_NAME \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --enabled-state Enabled
print_in_color "$YELLOW"  "Create an origin group and add origins to it. An origin group is a collection of origins that you want to route traffic to."
az afd origin-group create \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --origin-group-name $FRONTDOOR_ORIGIN_GROUP_NAME \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --probe-request-type GET \
    --probe-protocol Https \
    --probe-interval-in-seconds 60 \
    --probe-path / \
    --sample-size 4 \
    --successful-samples-required 3 \
    --additional-latency-in-milliseconds 50



print_in_color "$YELLOW" "Create a virtual network and subnet"
az network vnet create --resource-group $RESOURCE_GROUP --name $VNET_NAME --location $LOCATION --address-prefix 10.0.0.0/16

print_in_color "$YELLOW" "Create a subnet"
az network vnet subnet create --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name infrastructure-subnet --address-prefixes 10.0.0.0/23
print_in_color "$YELLOW" "Update the subnet to allow the environment to be delegated to it"
az network vnet subnet update --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name infrastructure-subnet --delegations Microsoft.App/environments
INFRASTRUCTURE_SUBNET=$(az network vnet subnet show --resource-group ${RESOURCE_GROUP} --vnet-name $VNET_NAME --name infrastructure-subnet --query "id" -o tsv | tr -d '[:space:]' )

print_in_color "$YELLOW" "Create an ACA environment"
az containerapp env create --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP --location "$LOCATION" --infrastructure-subnet-resource-id $INFRASTRUCTURE_SUBNET --internal-only 
export CONTAINERAPPS_ENVIRONMENT_ID=$(az containerapp env show --name ${CONTAINERAPPS_ENVIRONMENT} --resource-group ${RESOURCE_GROUP} --query id --out json | tr -d '"')
export ENVIRONMENT_DEFAULT_DOMAIN=$(az containerapp env show --name ${CONTAINERAPPS_ENVIRONMENT} --resource-group ${RESOURCE_GROUP} --query properties.defaultDomain --out json | tr -d '"')
print_in_color "$GREEN" " CONTAINERAPPS_ENVIRONMENT_ID = $CONTAINERAPPS_ENVIRONMENT_ID"
print_in_color "$GREEN" " ENVIRONMENT_DEFAULT_DOMAIN = $ENVIRONMENT_DEFAULT_DOMAIN"
export ENVIRONMENT_STATIC_IP=$(az containerapp env show --name ${CONTAINERAPPS_ENVIRONMENT} --resource-group ${RESOURCE_GROUP} --query properties.staticIp --out json | tr -d '"')

VNET_ID=$(az network vnet show --resource-group ${RESOURCE_GROUP} --name ${VNET_NAME} --query id --out json | tr -d '"') 
print_in_color "$GREEN" " CONTAINERAPPS_ENVIRONMENT_ID = $CONTAINERAPPS_ENVIRONMENT_ID"
print_in_color "$GREEN" " ENVIRONMENT_DEFAULT_DOMAIN = $ENVIRONMENT_DEFAULT_DOMAIN"
print_in_color "$GREEN" " ENVIRONMENT_STATIC_IP = $ENVIRONMENT_STATIC_IP"
print_in_color "$GREEN" " VNET_ID = $VNET_ID"
## Setup DNS

## mcr.microsoft.com/k8se/quickstart:latest
print_in_color "$YELLOW" "Create a private DNS zone"
az network private-dns zone create --resource-group $RESOURCE_GROUP --name $ENVIRONMENT_DEFAULT_DOMAIN
print_in_color "$YELLOW" "Create a virtual network link to the private DNS zone"
az network private-dns link vnet create --resource-group $RESOURCE_GROUP --name $VNET_NAME --virtual-network $VNET_ID --zone-name $ENVIRONMENT_DEFAULT_DOMAIN -e true
print_in_color "$YELLOW" "Add a record set to the private DNS zone"
az network private-dns record-set a add-record --resource-group $RESOURCE_GROUP --record-set-name "*" --ipv4-address $ENVIRONMENT_STATIC_IP --zone-name $ENVIRONMENT_DEFAULT_DOMAIN

print_in_color "$YELLOW" "Create a container app"
az containerapp create \
  --name $API_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image mcr.microsoft.com/k8se/quickstart:latest \
  --target-port 80 \
  --ingress external \
  --query properties.configuration.ingress.fqdn

export CONTAINER_APP_FQDN=$(az containerapp show --name $API_NAME --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn --out json --only-show-errors | tr -d '"')
print_in_color "$GREEN" " CONTAINER_APP_FQDN = $CONTAINER_APP_FQDN"
print_in_color "$YELLOW" "Create an origin"
az afd origin create \
 -g $RESOURCE_GROUP \
 -n $FRONTDOOR_ORIGIN_GROUP_NAME \
 --profile-name $FRONTDOOR_PROFILE_NAME \
 --origin-group-name $FRONTDOOR_ORIGIN_GROUP_NAME \
 --enable-private-link true \
 --private-link-location $LOCATION \
 --private-link-request-message "please approve" \
 --private-link-resource $CONTAINERAPPS_ENVIRONMENT_ID \
 --private-link-sub-resource-type managedEnvironments \
 --host-name $CONTAINER_APP_FQDN \
 --origin-host-header $CONTAINER_APP_FQDN \
 --priority 1  --weight 500

print_in_color  "$YELLOW" "Create a route"
az afd route create \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --endpoint-name $FRONTDOOR_ENDPOINT_NAME \
    --forwarding-protocol MatchRequest \
    --route-name bluegreen-route \
    --https-redirect Disabled \
    --origin-group $FRONTDOOR_ORIGIN_GROUP_NAME \
    --supported-protocols Https \
    --link-to-default-domain Enabled 
print_in_color "$YELLOW" "Approve the private link connection"
myid=$(az network private-endpoint-connection  list --id $CONTAINERAPPS_ENVIRONMENT_ID --query "[].id" -o tsv)
print_in_color "$GREEN" "Private endpoint connection = $myid"
print_in_color "$YELLOW" "Approve the private link connection"

az network private-endpoint-connection approve --id $myid  --description "Approved by ivan"


FRONTDOOR_ENDPOINT_NAME=$(az afd endpoint list --profile-name $FRONTDOOR_PROFILE_NAME --resource-group $FRONTDOOR_RESOURCE_GROUP --query "[?name=='$FRONTDOOR_ENDPOINT_NAME'].hostName" -o tsv)
print_in_color "$GREEN" "Frontdoor endpoint is: $FRONTDOOR_ENDPOINT_NAME"
print_in_color "$GREEN" "You can now test the deployment by running the following commands:"
print_in_color "$GREEN" "default= curl  -s https://$FRONTDOOR_ENDPOINT_NAME/ "

exit 0
