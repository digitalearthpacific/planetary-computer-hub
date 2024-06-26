resource "kubernetes_namespace" "argo" {
  metadata {
    name = "argo"
  }
}

resource "kubernetes_secret" "argo_server_sso" {

  metadata {
    name      = "argo-server-sso"
    namespace = kubernetes_namespace.argo.metadata[0].name
  }
  data = {
    client-id     = split(":", data.azurerm_key_vault_secret.argo_server_sso.value)[0]
    client-secret = split(":", data.azurerm_key_vault_secret.argo_server_sso.value)[1]
  }

  type = "Opaque"
}

# Create an azure storage account and container for argo to use
resource "azurerm_storage_account" "argo" {
  name                     = "${local.stack_id}${var.environment}storage"
  resource_group_name      = var.pc_resources_rg
  location                 = azurerm_resource_group.pc_compute.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = var.environment
  }
}

# Create the storage container
resource "azurerm_storage_container" "container" {
  name                  = "argo"
  storage_account_name  = azurerm_storage_account.argo.name
  container_access_type = "private"
}

data "azurerm_storage_account_blob_container_sas" "argo" {
  connection_string = azurerm_storage_account.argo.primary_connection_string
  container_name    = azurerm_storage_container.container.name
  https_only        = true

  start  = "2023-01-01"
  expiry = "2030-01-01"

  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = true
    list   = true
  }

  cache_control       = "max-age=5"
  content_disposition = "inline"
  content_encoding    = "deflate"
  content_language    = "en-US"
  content_type        = "application/json"
}

# Store the AZURE_STORAGE_KEY, AZURE_STORAGE_CONNECTION_STRING
# and AZURE_STORAGE_SAS_TOKEN in a secret
resource "kubernetes_secret" "argo_storage" {
  metadata {
    name      = "argo-storage-read-write"
    namespace = kubernetes_namespace.argo.metadata[0].name
  }
  data = {
    AZURE_STORAGE_KEY               = azurerm_storage_account.argo.primary_access_key
    AZURE_STORAGE_CONNECTION_STRING = azurerm_storage_account.argo.primary_connection_string
    AZURE_STORAGE_SAS_TOKEN         = data.azurerm_storage_account_blob_container_sas.argo.sas
  }

  type = "Opaque"
}

# Get an existing storage account
data "azurerm_storage_account" "deppcpublicstorage" {
  provider            = azurerm.storage
  name                = "deppcpublicstorage"
  resource_group_name = "dep-pc-main-rg"
}

data "azurerm_storage_container" "deppcpublicstorage_output" {
  provider             = azurerm.storage
  name                 = "output"
  storage_account_name = data.azurerm_storage_account.deppcpublicstorage.name
}

data "azurerm_storage_account_blob_container_sas" "deppcpublicstorage" {
  provider          = azurerm.storage
  connection_string = data.azurerm_storage_account.deppcpublicstorage.primary_connection_string
  container_name    = data.azurerm_storage_container.deppcpublicstorage_output.name
  https_only        = true

  start  = "2024-01-01"
  expiry = "2025-01-01"

  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = true
    list   = true
  }

  cache_control       = "max-age=5"
  content_disposition = "inline"
  content_encoding    = "deflate"
  content_language    = "en-US"
  content_type        = "application/json"
}

# Store the AZURE_STORAGE_KEY, AZURE_STORAGE_CONNECTION_STRING
resource "kubernetes_secret" "deppcpublicstorage_secret" {
  metadata {
    name      = "deppcpublicstorage-output-read-write"
    namespace = kubernetes_namespace.argo.metadata[0].name
  }
  data = {
    AZURE_STORAGE_ACCOUNT           = data.azurerm_storage_account.deppcpublicstorage.name
    AZURE_STORAGE_KEY               = data.azurerm_storage_account.deppcpublicstorage.primary_access_key
    AZURE_STORAGE_CONNECTION_STRING = data.azurerm_storage_account.deppcpublicstorage.primary_connection_string
    AZURE_STORAGE_SAS_TOKEN         = data.azurerm_storage_account_blob_container_sas.deppcpublicstorage.sas
  }

  type = "Opaque"
}
