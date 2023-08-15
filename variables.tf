
variable "resource_group_location" {
    type        = string
    default     = "eastus"
    description = "Resource group location"
}

variable "resource_group_name_prefix" {
    type    = string
    default = "rg"
    description = "Prefix of RG for unique name for all resources"
}