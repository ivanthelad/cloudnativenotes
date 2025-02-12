## checkout https://github.com/spring-petclinic/spring-petclinic-rest
CONTAINER_APP_ENVIRONMENT=dff-aca-env
RESOURCE_GROUP=fffff-aca-rg
LOCATION=swedencentral



##az containerapp up --name spring-petclinic-rest3 --resource-group $RESOURCE_GROUP --location $LOCATION --source springboot-aca/spring-petclinic  --ingress external --target-port 8080  --environment $CONTAINER_APP_ENVIRONMENT
##
az containerapp  revision set-mode --name spring-petclinic-rest3 --resource-group $RESOURCE_GROUP --mode multiple


az containerapp update --name spring-petclinic-rest3 --resource-group $RESOURCE_GROUP  --source springboot-aca/spring-petclinic 
