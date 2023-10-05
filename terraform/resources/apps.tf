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
