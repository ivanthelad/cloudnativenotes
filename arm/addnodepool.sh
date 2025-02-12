az aks nodepool add --resource-group $RESOURCE_GROUP \
    --cluster-name $CLUSTER_NAME \
    --name arm \
    --node-count 1 \
    --node-vm-size Standard_D2ps_v6 \
    --labels environment=production \
    --tags project=example


az aks nodepool add --resource-group rg-aksdemo \
    --cluster-name aks-k7iqiqxli4kz2 \
    --name armv6 \
    --node-count 2 \
    --node-vm-size Standard_D2ps_v6 \
    --labels environment=production \
    --tags project=example

az aks nodepool add --resource-group rg-aksdemo \
    --cluster-name aks-k7iqiqxli4kz2 \
    --name armv5 \
    --node-count 2 \
    --node-vm-size Standard_D2ps_v5 \
    --labels environment=production \
    --tags project=example

az aks nodepool update --resource-group rg-aksdemo \
    --cluster-name aks-k7iqiqxli4kz2 \
     --name arm  \
     --node-taints "sku=arm:NoSchedule" 


az aks nodepool add --resource-group rg-aksdemo \
    --cluster-name aks-k7iqiqxli4kz2 \
    --name x86 \
    --node-count 2 \
    --node-vm-size Standard_D2s_v3 \
    --labels environment=production \
    --tags project=example

az aks nodepool add \
    --resource-group rg-aksdemo \
    --cluster-name aks-k7iqiqxli4kz2 \
    --name npsystem2 \
    --node-count 3 \
    --node-vm-size Standard_D2ads_v5 \
    --node-taints "CriticalAddonsOnly=true:NoSchedule" \
   --mode System --zones 1 2 3

az aks nodepool update \
    --resource-group rg-aksdemo \
    --cluster-name aks-k7iqiqxli4kz2 \
    --name npsystem \
    --node-taints "CriticalAddonsOnly=true:NoSchedule" \
   --mode System

az aks nodepool add --resource-group rg-aksdemo \
    --cluster-name aks-k7iqiqxli4kz2 \
    --name armold \
    --node-count 1 \
    --node-vm-size Standard_D2ps_v5 \
    --labels environment=production \
    --node-taints sku=arm:NoSchedule \
    --tags project=example

az aks nodepool add --resource-group rg-aksdemo \
    --cluster-name aks-k7iqiqxli4kz2 \
    --name armv6 \
    --node-count 2 \
    --node-vm-size Standard_D2ps_v6 \
    --labels environment=production \
    --tags project=example

az aks nodepool add --resource-group rg-aksdemo \
    --cluster-name aks-k7iqiqxli4kz2 \
    --name armv6 \
    --node-count 2 \
    --node-vm-size Standard_D2ps_v6 \
    --labels environment=production \
    --node-taints sku=arm:NoSchedule \
    --tags project=example

docker build . \
    --platform linux/arm64 \
    -t crk7iqiqxli4kz2.azurecr.io/todo-nodejs-mongo-aks/api-aksdemo:arm64

docker build . \
    --platform linux/arm64 \
    -t crk7iqiqxli4kz2.azurecr.io/todo-nodejs-mongo-aks/api-aksdemo:arm64

docker  manifest inspect crk7iqiqxli4kz2.azurecr.io/todo-nodejs-mongo-aks/api-aksdemo:multiarc | grep architectur




crk7iqiqxli4kz2.azurecr.io/todo-nodejs-mongo-aks/api-aksdemo:arm64
azd-deploy-1737635531

## Add nodepool 
az aks nodepool add --resource-group rg-aksdemo \
    --cluster-name aks-k7iqiqxli4kz2 \
    --name armv6 \
    --node-count 2 \
    --node-vm-size Standard_D2ps_v6 \
    --labels environment=production \
    --node-taints sku=arm:NoSchedule \
    --tags project=example
## Revert changes 
kubectl patch deployment todo-api --patch '{"spec": {"template": {"spec": {"containers": [{"name": "todo-api", "image": "crk7iqiqxli4kz2.azurecr.io/todo-nodejs-mongo-aks/api-aksdemo:azd-deploy-1737635531"}]}}}}'

## patch container
kubectl patch deployment todo-api --patch '{"spec": {"template": {"spec": {"containers": [{"name": "todo-api", "image": "crk7iqiqxli4kz2.azurecr.io/todo-nodejs-mongo-aks/api-aksdemo:arm64"}]}}}}'

## Add toleration
kubectl patch deployment todo-api --patch '{
  "spec": {
    "template": {
      "spec": {
        "tolerations": [
          {
            "key": "sku",
            "value": "arm",
             "operator": "Equal",
            "effect": "NoSchedule"
          }
        ]
      }
    }
  }
}'
## remove tolerations 
kubectl patch deployment todo-api --type='json' -p='[{"op": "remove", "path": "/spec/template/spec/tolerations"}]'