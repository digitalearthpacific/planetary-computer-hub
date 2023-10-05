data "azurerm_key_vault" "deploy_secrets" {
  name                = var.pc_resources_kv
  resource_group_name = var.pc_resources_rg
}

# JupyterHub
data "azurerm_key_vault_secret" "jupyterhub_proxy_secret_token" {
  name         = "${local.namespaced_prefix}--jupyterhub-proxy-secret-token"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}

# API Management integration
data "azurerm_key_vault_secret" "autho_client_secret" {
  name         = "${local.stack_id}--autho-client-secret"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}

# kbatch integration
data "azurerm_key_vault_secret" "kbatch_server_api_token" {
  name         = "${local.namespaced_prefix}--kbatch-server-api-token"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}

# Argo
data "azurerm_key_vault_secret" "argo_server_sso" {
  name         = "${local.stack_id}--argo-clientid-clientsecret"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}

# Grafana
data "azurerm_key_vault_secret" "grafana_admin_secret" {
  name = "dep--grafana-admin-secret"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}

data "azurerm_key_vault_secret" "grafana_clientid_clientsecret" {
  name = "dep--grafana-clientid-clientsecret"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}

data "azurerm_key_vault_secret" "grafana_db_creds" {
  name = "dep--grafana-db-secret"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}

# PGSTAC
data "azurerm_key_vault_secret" "pgstac_db_creds_admin" {
  name = "dep--pgstac-admin"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}
data "azurerm_key_vault_secret" "pgstac_db_creds_read" {
  name = "dep--pgstac-read"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}
data "azurerm_key_vault_secret" "pgstac_db_creds_ingest" {
  name = "dep--pgstac-ingest"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}

# Terria
data "azurerm_key_vault_secret" "terria_bucket_writer" {
  name = "dep--terria-bucket-writer"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}
