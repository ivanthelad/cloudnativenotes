tolerations:
- key: "key1"
  operator: "Exists"
  effect: "NoSchedule"


  docker manifest inspect crk7iqiqxli4kz2.azurecr.io/todo-nodejs-mongo-aks/web-aksdemo:multi
cd finops/todo-nodejs-mongo-aks/src

Build 
 docker build -f ./api/Dockerfile --platform linux/arm64,linux/amd64 ./api/ -t crk7iqiqxli4kz2.azurecr.io/todo-nodejs-mongo-aks/api-aksdemo:multi
 docker build -f ./web/Dockerfile --platform linux/arm64,linux/amd64 ./web/ -t crk7iqiqxli4kz2.azurecr.io/todo-nodejs-mongo-aks/web-aksdemo:multi
Push
 docker push  crk7iqiqxli4kz2.azurecr.io/todo-nodejs-mongo-aks/api-aksdemo:multi
 docker push  crk7iqiqxli4kz2.azurecr.io/todo-nodejs-mongo-aks/web-aksdemo:multi

Add a node selector
      spec:
      nodeSelector:
        agentpool: armold

Add a toleration. 
      nodeSelector:
        agentpool: armold
      tolerations:
        - key: "sku"
          operator: "Equal"
          value: "arm"
          effect: "NoSchedule"
        



        az aks nodepool update \
    --resource-group $RESOURCE_GROUP_NAME \
    --cluster-name $CLUSTER_NAME \
    --name $NODE_POOL_NAME \
    --node-taints "sku=gpu:NoSchedule" \
    --no-wait