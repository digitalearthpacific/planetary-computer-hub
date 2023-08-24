resource "kubernetes_namespace" "pgstac" {
  metadata {
    name = "pgstac"
  }
}

resource "kubernetes_secret" "pgstac" {
  metadata {
    name      = "pgstac-credentials"
    namespace = kubernetes_namespace.pgstac.metadata[0].name
  }

  data = {
    username-admin : split(":", data.azurerm_key_vault_secret.pgstac_db_creds_admin.value)[0]
    password-admin : split(":", data.azurerm_key_vault_secret.pgstac_db_creds_admin.value)[1]
    username-read : split(":", data.azurerm_key_vault_secret.pgstac_db_creds_read.value)[0]
    password-read : split(":", data.azurerm_key_vault_secret.pgstac_db_creds_read.value)[1]
    username-ingest : split(":", data.azurerm_key_vault_secret.pgstac_db_creds_ingest.value)[0]
    password-ingest : split(":", data.azurerm_key_vault_secret.pgstac_db_creds_ingest.value)[1]
  }

  type = "Opaque"
}
