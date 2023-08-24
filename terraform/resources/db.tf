data "azurerm_key_vault_secret" "postgres_password_secret" {
  name         = "${local.namespaced_prefix}--postgres-password"
  key_vault_id = data.azurerm_key_vault.deploy_secrets.id
}

resource "azurerm_network_security_group" "db" {
  name                = "${local.namespaced_prefix}-db-nsg"
  location            = azurerm_resource_group.pc_compute.location
  resource_group_name = azurerm_resource_group.pc_compute.name

  security_rule {
    name                       = "db-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "db2" {
  name                 = "${local.namespaced_prefix}-db2-subnet"
  virtual_network_name = azurerm_virtual_network.pc_compute.name
  resource_group_name  = azurerm_resource_group.pc_compute.name
  address_prefixes     = ["10.2.0.0/16"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = azurerm_subnet.db2.id
  network_security_group_id = azurerm_network_security_group.db.id
}

resource "azurerm_private_dns_zone" "db" {
  name                = "${local.namespaced_prefix}-db-pdz.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.pc_compute.name

  depends_on = [azurerm_subnet_network_security_group_association.db]
}

resource "azurerm_private_dns_zone_virtual_network_link" "db" {
  name                  = "${local.namespaced_prefix}-db-pdzvnetlink.com"
  private_dns_zone_name = azurerm_private_dns_zone.db.name
  virtual_network_id    = azurerm_virtual_network.pc_compute.id
  resource_group_name   = azurerm_resource_group.pc_compute.name
}

resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "${local.namespaced_prefix}-db2-server"
  resource_group_name    = azurerm_resource_group.pc_compute.name
  location               = azurerm_resource_group.pc_compute.location
  version                = "13"
  delegated_subnet_id    = azurerm_subnet.db2.id
  private_dns_zone_id    = azurerm_private_dns_zone.db.id
  administrator_login    = "superadmin"
  administrator_password = data.azurerm_key_vault_secret.postgres_password_secret.value
  zone                   = "2"
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2s_v3"
  backup_retention_days  = 7

  depends_on = [azurerm_resource_group.pc_compute]
}

resource "azurerm_postgresql_flexible_server_configuration" "db" {
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.db.id
  value     = "off"
}

resource "azurerm_postgresql_flexible_server_configuration" "example" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.db.id
  value     = "POSTGIS,BTREE_GIST"
}

resource "kubernetes_namespace" "db" {
  metadata {
    name = "db"
  }
}

# Create a k8s secret
resource "kubernetes_secret" "db_admin_creds" {
  metadata {
    name      = "db-admin-creds"
    namespace = kubernetes_namespace.db.metadata[0].name
  }
  data = {
    username = "superadmin"
    password = data.azurerm_key_vault_secret.postgres_password_secret.value
    hostname = resource.azurerm_postgresql_flexible_server.db.fqdn
    internalhost = "db-endpoint.db.svc.cluster.local"
  }
  type = "Opaque"
}
resource "kubernetes_secret" "db_admin_creds_argo" {
  metadata {
    name      = "db-admin-creds"
    namespace = kubernetes_namespace.argo.metadata[0].name
  }
  data = {
    username = "superadmin"
    password = data.azurerm_key_vault_secret.postgres_password_secret.value
    hostname = resource.azurerm_postgresql_flexible_server.db.fqdn
    internalhost = "db-endpoint.db.svc.cluster.local"
  }
  type = "Opaque"
}

resource "kubernetes_service" "db_endpoint" {
  metadata {
    name      = "db-endpoint"
    namespace = kubernetes_namespace.db.metadata[0].name
  }
  spec {
    type          = "ExternalName"
    external_name = resource.azurerm_postgresql_flexible_server.db.fqdn
    port {
      port        = 5432
      target_port = 5432
    }
  }
  wait_for_load_balancer = false
}
