export UUID_SHORT=$(uuidgen | cut -c1-4 | tr '[:upper:]' '[:lower:]')
export FRONTDOOR_PROFILE_NAME="frontdoor-$UUID_SHORT"
export FRONTDOOR_RESOURCE_GROUP="frontdoor-$UUID_SHORT"
export FRONTDOOR_ENDPOINT_NAME="default-endpoint$UUID_SHORT"
export FRONTDOOR_ORIGIN_GROUP_NAME="default-origin-group"
export FRONTDOOR_ORIGIN_NAME_BLUE="origin-blue"
export FRONTDOOR_ORIGIN_NAME_GREEN="origin-green"
export FRONTDOOR_ORIGIN_GROUP_NAME_BLUE="origin-group-blue"
export FRONTDOOR_ORIGIN_GROUP_NAME_GREEN="origin-group-green"
export FRONTDOOR_RULESET="BlueGreenRuleSet"
export LOCATION="eastus"
export UUID_SHORT=$(uuidgen | cut -c1-4 | tr '[:upper:]' '[:lower:]')
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
print_in_color "$YELLOW" "This script will deploy a blue green deployment using Azure Front Door"
echo "This example performs the following" 
echo "- Deploys two Container instances. Blue + Green"
echo "- Evenly distributes traffic against them using and origin group consisting of blue and green"
echo " - deploys a rule set that checks for the header 'stage'" 
echo " -  If "green" is found then the origin is overwriten and routed to the green back end. "
echo " -  If "blue" is found then the origin is overwriten and routed to the blue back end."
echo " - Purpose is to allow clients within a cannary ring to test a new application version or infrastructure before release to the wider audience "
echo " "
print_in_color "$RED" "  O "
print_in_color "$RED" " /|\ "
print_in_color "$RED" " / \ "
print_in_color "$GREEN" "  | "
print_in_color "$GREEN" "  v "
echo "+-----------------+   +---------+ " | 
echo "|  Default Route  |-->| Ruleset | "
echo "+-----------------+   +---------+ "
print_in_color "$GREEN" "       |                |     | "
print_in_color "$GREEN" "       v                |     | "
echo "+---------------+       |     | "
echo "| Default 50/50 |       |     | "
echo "+---------------+       |     | "
print_in_color "$GREEN" "   |       |            |     | "
print_in_color "$GREEN" "   v       v            v     v "
echo "+------+ +------+   +------+ +------+ "
echo "| Blue | | Green|   | Blue | | Green | "
echo "+------+ +------+   +------+ +------+ "




az group create --name $FRONTDOOR_RESOURCE_GROUP --location $LOCATION

# Define the DNS name variable
BLUE_DNS_NAME="blueapp-$UUID_SHORT"

# Create the container with the DNS name and capture the output
responseblue=$(az container create \
    --image mcr.microsoft.com/k8se/samples/test-app:fb699ef \
    -g $FRONTDOOR_RESOURCE_GROUP \
    -n $BLUE_DNS_NAME \
    --ip-address Public \
    --ports 80 \
    --environment-variables REVISION_COMMIT_ID=fb699ef stage=BLUE \
    --dns-name-label $BLUE_DNS_NAME \
    --output json)

# Extract the DNS name from the response
blue_extracted_dns_name=$(echo $responseblue | jq -r '.ipAddress.fqdn')

# Output the extracted DNS name
print_in_color "$YELLOW"   "Extracted blueapp DNS name is: $blue_extracted_dns_name"

GREEN_DNS_NAME="greenapp-$UUID_SHORT"

# Create the container with the DNS name and capture the output
responsegreen=$(az container create \
    --image mcr.microsoft.com/k8se/samples/test-app:c6f1515 \
    -g $FRONTDOOR_RESOURCE_GROUP \
    -n $GREEN_DNS_NAME \
    --ip-address Public \
    --ports 80 \
    --environment-variables REVISION_COMMIT_ID=c6f1515 stage=GREEN \
    --dns-name-label $GREEN_DNS_NAME \
    --output json)

# Extract the DNS name from the response
green_extracted_dns_name=$(echo $responsegreen | jq -r '.ipAddress.fqdn')

# Output the extracted DNS name
print_in_color "$YELLOW"  "Extracted green DNS name is: $green_extracted_dns_name"

print_in_color "$YELLOW"  " 1 Creating Azure Front Door resources..."

az afd profile create \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --sku Standard_AzureFrontDoor  
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
    --probe-protocol Http \
    --probe-interval-in-seconds 60 \
    --probe-path / \
    --sample-size 4 \
    --successful-samples-required 3 \
    --additional-latency-in-milliseconds 50


print_in_color "$YELLOW"  "      Add a blue origin "
az afd origin create \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --host-name $blue_extracted_dns_name \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --origin-group-name $FRONTDOOR_ORIGIN_GROUP_NAME \
    --origin-name blue-default \
    --origin-host-header $blue_extracted_dns_name \
    --priority 1 \
    --weight 1000 \
    --enabled-state Enabled \
    --http-port 80 \
    --https-port 443
print_in_color "$YELLOW" " Add a second origin to the origin group. This origin represents the green deployment."
az afd origin create \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --host-name $green_extracted_dns_name \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --origin-group-name $FRONTDOOR_ORIGIN_GROUP_NAME \
    --origin-name green-default \
    --origin-host-header $green_extracted_dns_name \
    --priority 1 \
    --weight 1000 \
    --enabled-state Enabled \
    --http-port 80 \
    --https-port 443



##while true; do curl -s https://simplebluegreenheader-gbf3abaxa9a4ajgh.b01.azurefd.net/api/env | jq | grep stage; sleep 1; done

##while true; do curl -s http://simplebluegreenheader-gbf3abaxa9a4ajgh.b01.azurefd.net/api/env | jq | grep stage; sleep 1; done

##while true; do curl -H "stage: blue"-s http://simplebluegreenheader-gbf3abaxa9a4ajgh.b01.azurefd.net/api/env | jq | grep stage; sleep 1; done

print_in_color "$YELLOW"  " 1.1 Create Blue OG"
az afd origin-group create \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --origin-group-name $FRONTDOOR_ORIGIN_GROUP_NAME_BLUE \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --probe-request-type GET \
    --probe-protocol Http \
    --probe-interval-in-seconds 60 \
    --probe-path / \
    --sample-size 4 \
    --successful-samples-required 3 \
    --additional-latency-in-milliseconds 50
print_in_color "$YELLOW" " 1.2 create blue origin and add to blue group "
az afd origin create \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --host-name 51.138.2.125 \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --origin-group-name $FRONTDOOR_ORIGIN_GROUP_NAME_BLUE \
    --origin-name $FRONTDOOR_ORIGIN_NAME_BLUE \
    --origin-host-header 51.138.2.125 \
    --priority 1 \
    --weight 1000 \
    --enabled-state Enabled \
    --http-port 80 \
    --https-port 443

print_in_color "$YELLOW" " 2.1 Create Green OG"
    
az afd origin-group create \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --origin-group-name $FRONTDOOR_ORIGIN_GROUP_NAME_GREEN \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --probe-request-type GET \
    --probe-protocol Http \
    --probe-interval-in-seconds 60 \
    --probe-path / \
    --sample-size 4 \
    --successful-samples-required 3 \
    --additional-latency-in-milliseconds 50

print_in_color "$YELLOW" " 2.2 create green origin and add to green group "
az afd origin create \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --host-name 20.23.141.232 \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --origin-group-name $FRONTDOOR_ORIGIN_GROUP_NAME_GREEN  \
    --origin-name $FRONTDOOR_ORIGIN_NAME_GREEN \
    --origin-host-header 20.23.141.232 \
    --priority 1 \
    --weight 1000 \
    --enabled-state Enabled \
    --http-port 80 \
    --https-port 443



 print_in_color "$YELLOW" " 1 Create a rule set:"
az afd rule-set create \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --rule-set-name $FRONTDOOR_RULESET
print_in_color "$YELLOW" " 2.1 Add a rule to the rule set to route based on a header:"
az afd rule create \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --rule-set-name $FRONTDOOR_RULESET \
    --rule-name routeByHeaderBlue \
 --action-name RouteConfigurationOverride  --origin-group $FRONTDOOR_ORIGIN_GROUP_NAME_BLUE    --order 1
print_in_color "$YELLOW" " 2.2  Add a match condition to the rule to match the header for blue:"
az afd rule condition add \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --rule-set-name $FRONTDOOR_RULESET \
    --rule-name routeByHeaderBlue \
    --match-variable RequestHeader \
    --operator Equal \
    --match-values blue \
    --selector stage

print_in_color "$YELLOW" " 3.1 Add a rule to the rule set to route based on a header:"
az afd rule create \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --rule-set-name $FRONTDOOR_RULESET \
    --rule-name routeByHeaderGreen \
    --action-name RouteConfigurationOverride  --origin-group $FRONTDOOR_ORIGIN_GROUP_NAME_GREEN    --order 2

print_in_color "$YELLOW" " 3.2  Add a match condition to the rule to match the header for blue:"
## 
az afd rule condition add \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --rule-set-name $FRONTDOOR_RULESET \
    --rule-name routeByHeaderGreen \
    --match-variable RequestHeader \
    --operator Equal \
    --match-values green \
    --selector stage

print_in_color "$YELLOW" " 4.1 Add a rule to the rule set to route based on a header:"


## 4. Add the rule set to the endpoint
print_in_color "$YELLOW" " 4.2 Aattache route to endpoint"
az afd route create \
    --resource-group $FRONTDOOR_RESOURCE_GROUP \
    --profile-name $FRONTDOOR_PROFILE_NAME \
    --endpoint-name $FRONTDOOR_ENDPOINT_NAME \
    --forwarding-protocol MatchRequest \
    --route-name bluegreen-route \
    --https-redirect Disabled \
    --origin-group $FRONTDOOR_ORIGIN_GROUP_NAME \
    --supported-protocols Http \
    --link-to-default-domain Enabled \
     --rule-set $FRONTDOOR_RULESET

//extract the frontdoor default endpoint using az command 
FRONTDOOR_ENDPOINT_NAME=$(az afd endpoint list --profile-name $FRONTDOOR_PROFILE_NAME --resource-group $FRONTDOOR_RESOURCE_GROUP --query "[?name=='$FRONTDOOR_ENDPOINT_NAME'].hostName" -o tsv)
print_in_color "$GREEN" "Frontdoor endpoint is: $FRONTDOOR_ENDPOINT_NAME"
print_in_color "$GREEN" "You can now test the deployment by running the following commands:"
print_in_color "$GREEN" "BLUE= curl -H 'stage: blue' -s http://$FRONTDOOR_ENDPOINT_NAME/api/env | jq | grep stage"
print_in_color "$GREEN" "Green= curl -H 'stage: green' -s http://$FRONTDOOR_ENDPOINT_NAME/api/env | jq | grep stage"
print_in_color "$GREEN" "Deault= curl  -s http://$FRONTDOOR_ENDPOINT_NAME/api/env | jq | grep stage"


## simplebluegreenheader-gbf3abaxa9a4ajgh.b01.azurefd.net





