#https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/container-apps/java-microservice-get-started.md
export PREFIX=demo9123
export RESOURCE_GROUP=$PREFIX-rg
export LOCATION=swedencentral
export CONTAINER_APP_ENVIRONMENT=$PREFIX-aca-env

export CONFIG_SERVER_COMPONENT=configserver
export ADMIN_SERVER_COMPONENT=admin
export EUREKA_SERVER_COMPONENT=eureka
export CONFIG_SERVER_URI=https://github.com/spring-petclinic/spring-petclinic-microservices-config.git
export CUSTOMERS_SERVICE=customers-service
export VETS_SERVICE=vets-service
export VISITS_SERVICE=visits-service
export API_GATEWAY=api-gateway
export CUSTOMERS_SERVICE_IMAGE=ghcr.io/azure-samples/javaaccelerator/spring-petclinic-customers-service
export VETS_SERVICE_IMAGE=ghcr.io/azure-samples/javaaccelerator/spring-petclinic-vets-service
export VISITS_SERVICE_IMAGE=ghcr.io/azure-samples/javaaccelerator/spring-petclinic-visits-service
export API_GATEWAY_IMAGE=ghcr.io/azure-samples/javaaccelerator/spring-petclinic-api-gateway
# Create a resource group
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION
# Create a container app environment
az containerapp env create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_APP_ENVIRONMENT \
    --location $LOCATION
az containerapp env java-component config-server-for-spring create \
    --resource-group $RESOURCE_GROUP \
    --name $CONFIG_SERVER_COMPONENT \
    --environment $CONTAINER_APP_ENVIRONMENT \
    --configuration spring.cloud.config.server.git.uri=$CONFIG_SERVER_URI

az containerapp env java-component eureka-server-for-spring create \
    --resource-group $RESOURCE_GROUP \
    --name $EUREKA_SERVER_COMPONENT \
    --environment $CONTAINER_APP_ENVIRONMENT \

az containerapp env java-component admin-for-spring create \
    --resource-group $RESOURCE_GROUP \
    --name $ADMIN_SERVER_COMPONENT \
    --environment $CONTAINER_APP_ENVIRONMENT 

az containerapp create \
    --resource-group $RESOURCE_GROUP \
    --name $CUSTOMERS_SERVICE \
    --environment $CONTAINER_APP_ENVIRONMENT \
    --image $CUSTOMERS_SERVICE_IMAGE

az containerapp create \
    --resource-group $RESOURCE_GROUP \
    --name $VETS_SERVICE \
    --environment $CONTAINER_APP_ENVIRONMENT \
    --image $VETS_SERVICE_IMAGE

az containerapp create \
    --resource-group $RESOURCE_GROUP \
    --name $VISITS_SERVICE \
    --environment $CONTAINER_APP_ENVIRONMENT \
    --image $VISITS_SERVICE_IMAGE

az containerapp create \
    --resource-group $RESOURCE_GROUP \
    --name $API_GATEWAY \
    --environment $CONTAINER_APP_ENVIRONMENT \
    --image $API_GATEWAY_IMAGE \
    --ingress external \
    --target-port 8080 \
    --query properties.configuration.ingress.fqdn 

az containerapp update \
    --resource-group $RESOURCE_GROUP \
    --name $CUSTOMERS_SERVICE \
    --bind $CONFIG_SERVER_COMPONENT $EUREKA_SERVER_COMPONENT $ADMIN_SERVER_COMPONENT

az containerapp update \
    --resource-group $RESOURCE_GROUP \
    --name $VETS_SERVICE \
    --bind $CONFIG_SERVER_COMPONENT $EUREKA_SERVER_COMPONENT $ADMIN_SERVER_COMPONENT

az containerapp update \
    --resource-group $RESOURCE_GROUP \
    --name $VISITS_SERVICE \
    --bind $CONFIG_SERVER_COMPONENT $EUREKA_SERVER_COMPONENT $ADMIN_SERVER_COMPONENT

az containerapp update \
    --resource-group $RESOURCE_GROUP \
    --name $API_GATEWAY \
    --bind $CONFIG_SERVER_COMPONENT $EUREKA_SERVER_COMPONENT $ADMIN_SERVER_COMPONENT \
    --query properties.configuration.ingress.fqdn 