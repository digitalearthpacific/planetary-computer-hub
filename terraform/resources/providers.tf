provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias           = "storage"
  subscription_id = "b91e3470-ff50-4ea0-a0c7-b57006093805"
  features {}
}

provider "helm" {
  # https://dev.to/danielepolencic/getting-started-with-terraform-and-kubernetes-on-azure-aks-3l4d
  kubernetes {
    host                   = azurerm_kubernetes_cluster.pc_compute.kube_config[0].host
    client_key             = base64decode(azurerm_kubernetes_cluster.pc_compute.kube_config[0].client_key)
    client_certificate     = base64decode(azurerm_kubernetes_cluster.pc_compute.kube_config[0].client_certificate)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.pc_compute.kube_config[0].cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      # Note: The AAD server app ID of AKS Managed AAD is always 6dae42f8-4368-4678-94ff-3960e28e3630 in any environments.
      # See https://github.com/Azure/kubelogin#exec-plugin-format
      args    = ["get-token", "--environment", "AzurePublicCloud", "-l", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
      command = "kubelogin"
    }
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.pc_compute.kube_config[0].host
  client_key             = base64decode(azurerm_kubernetes_cluster.pc_compute.kube_config[0].client_key)
  client_certificate     = base64decode(azurerm_kubernetes_cluster.pc_compute.kube_config[0].client_certificate)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.pc_compute.kube_config[0].cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    # Note: The AAD server app ID of AKS Managed AAD is always 6dae42f8-4368-4678-94ff-3960e28e3630 in any environments.
    # See https://github.com/Azure/kubelogin#exec-plugin-format
    args    = ["get-token", "--environment", "AzurePublicCloud", "-l", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
    command = "kubelogin"
  }

}


terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.63.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.21.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.10.1"
    }
  }
}
