provider "azurerm" {
  features {}
}

locals {
  resource_group     = "dep-staging-rg"
  traefik_ip_address = "20.23.46.156"
  applications       = ["argo", "grafana", "titiler", "stac", "stac-browser", "stac-api"]
}

# Load the existing Azure DNS zone
data "azurerm_dns_zone" "staging" {
  name                = "staging.digitalearthpacific.org"
  resource_group_name = local.resource_group
}

# Create a DNS record for each application
resource "azurerm_dns_a_record" "applications" {
  for_each = toset(local.applications)

  name                = each.key
  zone_name           = data.azurerm_dns_zone.staging.name
  resource_group_name = local.resource_group
  ttl                 = 300
  records             = [local.traefik_ip_address]
}
