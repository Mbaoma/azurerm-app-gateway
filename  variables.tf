variable "sku_name" {
  type        = string
  default     = "Standard_Small"
  description = "SKU"
}

variable "tier" {
  type        = string
  default     = "Standard"
  description = "Tier"
}

variable "capacity" {
  type        = number
  default     = 2
  description = "SKU capacity"
}

