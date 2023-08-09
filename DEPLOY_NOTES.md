# Notes on deploying the Planetary Computer Hub to Azure

## State storage

Set up a storage space for Terraform: https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli

``` bash
#!/bin/bash

RESOURCE_GROUP_NAME=dep-staging
STORAGE_ACCOUNT_NAME=depstagingterraform
CONTAINER_NAME=dep-staging-state
REGION=westeurope

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $REGION

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME
```

``` bash
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)
export ARM_ACCESS_KEY=$ACCOUNT_KEY
```

## Service account

``` bash
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/99ad928a-19f5-491b-ae04-620dc650944a"
```

## Manual resources

Create a keyvault:

``` bash
az keyvault create --resource-group dep-staging --location westeurope --name dep-staging-secrets
```

Add keys to it:

``` bash
# Long strings to use for secrets in proxies
az keyvault secret set \
  --name=dep-staging--jupyterhub-proxy-secret-token \
  --vault-name=dep-staging-secrets \
  --value="$(openssl rand -hex 32)"

az keyvault secret set \
  --name=dep-staging--kbatch-server-api-token \
  --vault-name=dep-staging-secrets \
  --value="$(openssl rand -hex 32)"

# A secret for OAuth...
az keyvault secret set \
  --name=dep--autho-client-secret \
  --vault-name=dep-staging-secrets \
  --value=SECRET_FROM_AUTH0

# User/role for auth... disbled for now
# pcc--pc-id-token
# pcc--azure-client-secret
```

## Terraform commands

Export key variables:

``` bash
AZURE_CLIENT_ID="253f51ab-a4ec-4dec-a462-266226d680e5",
AZURE_CLIENT_SECRET="SECRET_ASK_ALEX",
AZURE_TENANT_ID="f721524d-ea60-4048-bc46-757d4b5f9fe8"
```

Pick the appropriate account, i.e,:

``` bash
az account set --subscription "99ad928a-19f5-491b-ae04-620dc650944a"
```

Run plan:

``` bash
terraform -chdir=terraform/dep-staging  plan \
  -var azure_client_id=$AZURE_CLIENT_ID \
  -var azure_client_secret=$AZURE_CLIENT_SECRET \
  -var azure_tenant_id=$AZURE_TENANT_ID \
  -var pc_resources_kv=dep-staging-secrets \
  -var pc_resources_rg=dep-staging
```

then run apply:

``` bash
terraform -chdir=terraform/dep-staging  apply \ 
  -var azure_client_id=$AZURE_CLIENT_ID \
  -var azure_client_secret=$AZURE_CLIENT_SECRET \
  -var azure_tenant_id=$AZURE_TENANT_ID \
  -var pc_resources_kv=dep-staging-secrets \
  -var pc_resources_rg=dep-staging
```

This may fail the first time, and you should set up a role assignment
on the Kubernetes cluster to give the deployer (you, or the system account)
"Azure Kubernetes Service RBAC Cluster Admin" permissions.

## Connect to k8s

``` bash
az aks get-credentials --resource-group dep-staging-rg --name dep-staging-cluster

kubectl get pods -A
```

## Helm chart update

You might need to change into the Helm directory and update the charts with
`helm dependency update`.

## More

Add GPU nodegroup, see [gpu.sh](scripts/gpu.sh)

``` bash
az feature register --namespace "Microsoft.ContainerService" --name "GPUDedicatedVHDPreview"
az provider register --namespace Microsoft.ContainerService
```

Then:

``` bash
# Workers (dask)
az aks nodepool add --name gpuworker \
    --cluster-name dep-staging-cluster \
    --resource-group dep-staging-rg \
    --node-vm-size Standard_NC4as_T4_v3 \
    --enable-cluster-autoscaler \
    --node-count 0 \
    --min-count=0 --max-count 25 \
    --priority Spot \
    --eviction-policy Delete \
    --spot-max-price -1 \
    --aks-custom-headers UseGPUDedicatedVHD=true \
    --labels k8s.dask.org/dedicated=worker pc.microsoft.com/workerkind=gpu

# Users (Jupyter)
az aks nodepool add --name gpuuser \
    --cluster-name dep-staging-cluster \
    --resource-group dep-staging-rg \
    --node-vm-size Standard_NC4as_T4_v3 \
    --enable-cluster-autoscaler \
    --node-count 0 \
    --min-count=0 --max-count 25 \
    --aks-custom-headers UseGPUDedicatedVHD=true \
    --labels hub.jupyter.org/node-purpose=user hub.jupyter.org/pool-name=user-alpha-pool pc.microsoft.com/userkind=gpu \
    --node-taints "hub.jupyter.org_dedicated=user:NoSchedule"
```

## Argo secrets

``` bash
# OAuth Secret for Argo Workflows
az keyvault secret set \
  --name=dep--argo-clientid-clientsecret \
  --vault-name=dep-staging-secrets \
  --value=CLIENT_ID:CLIENT_SECRET
```
