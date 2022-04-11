resource "azurerm_resource_group" "api-rg" {
  name     = "api-rg"
  location = "East US"
}

resource "azurerm_virtual_network" "v-net" {
  name                = "v-net"
  resource_group_name = azurerm_resource_group.api-rg.name
  location            = azurerm_resource_group.api-rg.location
  address_space       = ["10.254.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.api-rg.name
  virtual_network_name = azurerm_virtual_network.v-net.name
  address_prefixes     = ["10.254.0.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.api-rg.name
  virtual_network_name = azurerm_virtual_network.v-net.name
  address_prefixes     = ["10.254.2.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "example-pip"
  resource_group_name = azurerm_resource_group.api-rg.name
  location            = azurerm_resource_group.api-rg.location
  allocation_method   = "Dynamic"
}

#&nbsp;since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.v-net.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.v-net.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.v-net.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.v-net.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.v-net.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.v-net.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.v-net.name}-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
  name                = "app-gw"
  resource_group_name = azurerm_resource_group.api-rg.name
  location            = azurerm_resource_group.api-rg.location

  sku {
    name     = var.sku_name
    tier     = var.tier
    capacity = var.capacity
  }

  gateway_ip_configuration {
    name      = "gw-ip-config"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
    ssl_certificate_name           =  "appgw-ssl"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  redirect_configuration {
      name                  = "redirection"
      redirect_type         = "Temporary"
      target_url            = "https://google.com"
      include_path          = false
      include_query_string  = true
  }

  ssl_certificate {
      name              = "appgw-ssl"
      data              = filebase64("certificate.pfx")
    #   password            = "terraform"
  }
}
 