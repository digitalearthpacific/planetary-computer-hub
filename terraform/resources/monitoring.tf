resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_secret" "grafana_db_creds" {

  metadata {
    name      = "grafana-db-secret"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  data = {
    admin-user     = split(":", data.azurerm_key_vault_secret.grafana_db_creds.value)[0]
    admin-password = split(":", data.azurerm_key_vault_secret.grafana_db_creds.value)[1]
  }

  type = "Opaque"
}

resource "kubernetes_secret" "grafana_admin_credentials" {

  metadata {
    name      = "grafana-admin-secret"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  data = {
    admin-user     = split(":", data.azurerm_key_vault_secret.grafana_admin_secret.value)[0]
    admin-password = split(":", data.azurerm_key_vault_secret.grafana_admin_secret.value)[1]
  }

  type = "Opaque"
}

data "template_file" "grafana" {
  template = file("${path.module}/config/grafana.yaml")
  vars = {
    db_host     = kubernetes_service.db_endpoint.spec[0].external_name
    db_user     = split(":", data.azurerm_key_vault_secret.grafana_db_creds.value)[0]
    db_password = split(":", data.azurerm_key_vault_secret.grafana_db_creds.value)[1]

    # Probably should use secret manager for the client_secret
    client_id     = split(":", data.azurerm_key_vault_secret.grafana_clientid_clientsecret.value)[0]
    client_secret = split(":", data.azurerm_key_vault_secret.grafana_clientid_clientsecret.value)[1]
  }
}

resource "kubernetes_secret" "grafana" {
  metadata {
    name      = "grafana-values"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "values.yaml" = data.template_file.grafana.rendered
  }

  type = "Opaque"
}