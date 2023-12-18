resource "kubernetes_secret" "terria_bucket_writer" {

  metadata {
    name      = "terria-bucket-creds"
    namespace = "terria"
  }
  data = {
    access-key     = split(":", data.azurerm_key_vault_secret.terria_bucket_writer.value)[0]
    secret-key = split(":", data.azurerm_key_vault_secret.terria_bucket_writer.value)[1]
  }

  type = "Opaque"
}

resource "kubernetes_namespace" "odc" {
  metadata {
    name = "odc"
  }
}

resource "kubernetes_secret" "odc_admin_credentials" {
  
    metadata {
      name      = "odc-admin-credentials"
      namespace = kubernetes_namespace.odc.metadata[0].name
    }
    data = {
      username     = split(":", data.azurerm_key_vault_secret.odc_admin_credentials.value)[0]
      password = split(":", data.azurerm_key_vault_secret.odc_admin_credentials.value)[1]
    }
  
    type = "Opaque"
}
resource "kubernetes_secret" "odc_admin_credentials_argo" {
  
    metadata {
      name      = "odc-admin-credentials"
      namespace = "argo"
    }
    data = {
      username     = split(":", data.azurerm_key_vault_secret.odc_admin_credentials.value)[0]
      password = split(":", data.azurerm_key_vault_secret.odc_admin_credentials.value)[1]
    }
  
    type = "Opaque"
}

resource "kubernetes_secret" "odc_read_credentials" {
  
    metadata {
      name      = "odc-read-credentials"
      namespace = kubernetes_namespace.odc.metadata[0].name
    }
    data = {
      username     = split(":", data.azurerm_key_vault_secret.odc_read_credentials.value)[0]
      password = split(":", data.azurerm_key_vault_secret.odc_read_credentials.value)[1]
    }
  
    type = "Opaque"
}
