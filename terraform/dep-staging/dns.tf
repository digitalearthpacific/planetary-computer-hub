# We should be able to remove this... not sure why we can't!
provider "azurerm" {
  features {}
}

# TODO: get the load balancer IP from the kubernetes service

locals {
  resource_group     = "dep-staging-rg"
  traefik_ip_address = "20.61.135.58"
  # All the duplicates are due to the certificate issue Dec 2023 and can be removed in Jan 2024
  applications = [
    "argo", "argo-too",
    "grafana", "grafana-too",
    "titiler", "titiler-too",
    "stac", "stac-too",
    "stac-browser", "stac-browser-too",
    "ows", "ows-too",
    "maps"
  ]
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
