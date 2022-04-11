output "api-path" {
  value       = "azurerm_application_gateway.network.backend_http_settings.path"
  sensitive   = false
  description = "API Path"
  depends_on  = []
}
