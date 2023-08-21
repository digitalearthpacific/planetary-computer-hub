data "azurerm_key_vault_secret" "postgres_password_secret" {
  name         = "${local.namespaced_prefix}--postgres-password"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}


module "postgresql" {
  source = "Azure/postgresql/azurerm"

  resource_group_name = azurerm_resource_group.pc_compute.name
  location            = azurerm_resource_group.pc_compute.location

  server_name                   = "${local.namespaced_prefix}-postgres"
  sku_name                      = "GP_Gen5_2"
  storage_mb                    = 5120
  auto_grow_enabled             = false
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  administrator_login           = "superadmin"
  administrator_password        = data.azurerm_key_vault_secret.postgres_password_secret.value
  server_version                = "9.5"
  ssl_enforcement_enabled       = true
  public_network_access_enabled = false
  db_names                      = ["main"]
  db_charset                    = "UTF8"
  db_collation                  = "English_United States.1252"

  # firewall_rule_prefix = "firewall-"
  # firewall_rules = [
  #   { name = "test1", start_ip = "10.0.0.5", end_ip = "10.0.0.8" },
  #   { start_ip = "127.0.0.0", end_ip = "127.0.1.0" },
  # ]

  # vnet_rule_name_prefix = "postgresql-vnet-rule-"
  # vnet_rules = [
  #   { name = "subnet1", subnet_id = "<subnet_id>" }
  # ]

  tags = {
    Environment = var.environment,
  }

  postgresql_configurations = {
    backslash_quote = "on",
  }

  depends_on = [azurerm_resource_group.pc_compute]
}

resource "kubernetes_service" "db_endpoint" {
  metadata {
    name      = "db-endpoint"
    namespace = "default"
  }
  spec {
    type          = "ExternalName"
    external_name = module.postgresql.server_fqdn
    port {
      port        = 5432
      target_port = 5432
    }
  }
  wait_for_load_balancer = false
}
