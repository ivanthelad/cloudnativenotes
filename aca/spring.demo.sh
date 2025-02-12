export PREFIX=dff34
export LOCATION=swedencentral
export RESOURCE_GROUP=$PREFIX-aca-rg
export ENVIRONMENT=$PREFIX-aca-env
export JAVA_COMPONENT_NAME=admin
export APP_NAME=sample-admin-client
export IMAGE="mcr.microsoft.com/javacomponents/samples/sample-admin-for-spring-client:latest"
az group create --name $RESOURCE_GROUP --location $LOCATION --query "properties.provisioningState"

az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --query "properties.provisioningState"
az containerapp env create --name $ENVIRONMENT --resource-group $RESOURCE_GROUP --location $LOCATION

az containerapp env java-component admin-for-spring create --environment $ENVIRONMENT --resource-group $RESOURCE_GROUP --name $JAVA_COMPONENT_NAME --min-replicas 1 --max-replicas 1

az containerapp env java-component admin-for-spring update --environment $ENVIRONMENT --resource-group $RESOURCE_GROUP --name $JAVA_COMPONENT_NAME --min-replicas 2 --max-replicas 2

az containerapp create --name $APP_NAME --resource-group $RESOURCE_GROUP --environment $ENVIRONMENT --image $IMAGE --min-replicas 1 --max-replicas 1 --ingress external --target-port 8080 --bind $JAVA_COMPONENT_NAME

export ENVIRONMENT_ID=$(az containerapp env show \
    --name $ENVIRONMENT --resource-group $RESOURCE_GROUP \ 
    --query id \
    --output tsv)

az containerapp env java-component admin-for-spring show \
    --environment $ENVIRONMENT \
    --resource-group $RESOURCE_GROUP \
    --name $JAVA_COMPONENT_NAME \
    --query properties.ingress.fqdn \
    --output tsv