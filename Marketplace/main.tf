resource "azurerm_resource_group" "marketplace" {
  name     = "marketplace-dev"
  location = "West Europe"
}

resource "azurerm_service_plan" "marketplace" {
  name                = "marketplace-dev"
  location            = azurerm_resource_group.marketplace.location
  resource_group_name = azurerm_resource_group.marketplace.name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "marketplace" {
  name                = "marketplace-front-dev"
  location            = azurerm_resource_group.marketplace.location
  resource_group_name = azurerm_resource_group.marketplace.name
  service_plan_id     = azurerm_service_plan.marketplace.id
  virtual_network_subnet_id = azurerm_subnet.marketplace_webapp.id
  connection_string {
    name          = "psql"
    type          = "PostgreSQL"
    value         = "postgresql://psqladmin:${var.PSQL_PASSWORD}@${azurerm_postgresql_flexible_server.marketplace.fqdn}:5432/postgres"
  }
  
  site_config {
    vnet_route_all_enabled = true
    application_stack {
      docker_image_name = "marketplace-backend-api:1.0"
      docker_registry_url = "https://globalsoftwarehouse.azurecr.io"
  }
  }

  app_settings = {
    "DATABASE_URL" = "postgresql://psqladmin:${var.PSQL_PASSWORD}@${azurerm_postgresql_flexible_server.marketplace.fqdn}:5432/postgres"
    "PROJECT_NAME"= "Vehicle License Plate Recognition"
    "SECRET_KEY"= "z35v0hsbvxxsd-=fy3$mhmd!z675z$1nlas2kw#$0p8#d-p4$@"
    "ANPR_API_ENDPOINT"= "https://api.armell.ai/api/v2/recognize_bytes/"
    "ANPR_API_USER"= "brian"
    "ANPR_API_PASSWORD"= "theengiekuec3oekaum6Mu!u0"

  }
}

resource "azurerm_postgresql_flexible_server" "marketplace" {
  name                   = "marketplace-dev"
  resource_group_name    = azurerm_resource_group.marketplace.name
  location               = azurerm_resource_group.marketplace.location
  version                = "13"
  delegated_subnet_id    = azurerm_subnet.marketplace_sql.id
  private_dns_zone_id    = azurerm_private_dns_zone.marketplace.id
  administrator_login    = "psqladmin"
  administrator_password = var.PSQL_PASSWORD
  zone                   = "1"

  storage_mb = 32768

  sku_name   = "B_Standard_B1ms"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.marketplace]

}

resource "azurerm_virtual_network" "marketplace" {
  name                = "marketplace-dev"
  location            = azurerm_resource_group.marketplace.location
  resource_group_name = azurerm_resource_group.marketplace.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "marketplace_sql" {
  name                 = "marketplace-sql-dev"
  resource_group_name  = azurerm_resource_group.marketplace.name
  virtual_network_name = azurerm_virtual_network.marketplace.name
  address_prefixes     = ["10.0.2.0/24"]
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

resource "azurerm_subnet" "marketplace_webapp" {
  name                 = "marketplace-webapp"
  resource_group_name  = azurerm_resource_group.marketplace.name
  virtual_network_name = azurerm_virtual_network.marketplace.name
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
    name = "webapp-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
}
}

resource "azurerm_nat_gateway" "marketplace" {
  name                = "marketplace-dev"
  location            = azurerm_resource_group.marketplace.location
  resource_group_name = azurerm_resource_group.marketplace.name
}

resource "azurerm_public_ip" "marketplace" {
  name                = "marketplace-dev"
  location            = azurerm_resource_group.marketplace.location
  resource_group_name = azurerm_resource_group.marketplace.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "marketplace" {
  nat_gateway_id       = azurerm_nat_gateway.marketplace.id
  public_ip_address_id = azurerm_public_ip.marketplace.id
}

resource "azurerm_private_dns_zone" "marketplace" {
  name                = "sql.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.marketplace.name
}

resource "azurerm_subnet_nat_gateway_association" "marketplace" {
  subnet_id      = azurerm_subnet.marketplace_webapp.id
  nat_gateway_id = azurerm_nat_gateway.marketplace.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "marketplace" {
  name                  = "marketplace-dev"
  private_dns_zone_name = azurerm_private_dns_zone.marketplace.name
  virtual_network_id    = azurerm_virtual_network.marketplace.id
  resource_group_name   = azurerm_resource_group.marketplace.name
}

# Variables
variable "PSQL_PASSWORD" {
  description = "The password used for the PostgreSQL admin."
  default     = "x!H1R52mGLrPa%"
}

