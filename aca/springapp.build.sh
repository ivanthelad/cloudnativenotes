## checkout https://github.com/spring-petclinic/spring-petclinic-rest
CONTAINER_APP_ENVIRONMENT=ffff-aca-env
RESOURCE_GROUP=ffff-aca-rg
LOCATION=swedencentral

## Deploy app 
az containerapp up --name spring-petclinic-rest --resource-group $RESOURCE_GROUP --location $LOCATION --image springcommunity/spring-petclinic-rest --ingress external --target-port 9966  --environment $CONTAINER_APP_ENVIRONMENT


az containerapp up --name spring-petclinic-rest2 --resource-group $RESOURCE_GROUP --location $LOCATION --source springboot-aca/spring-petclinic-rest  --ingress external --target-port 9966  --environment $CONTAINER_APP_ENVIRONMENT
