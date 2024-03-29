
output "resource_group_name" {
    value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
    value = azurerm_linux_virtual_machine.main.public_ip_address
}

output "tls_private_key" {
    value = tls_private_key.rsakey.private_key_pem
    sensitive = true
}