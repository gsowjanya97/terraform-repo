resource "null_resource" "addfile" {
  provisioner "file" {
        source = "index.html"
        destination = "/var/www/html/index.html"
        connection {
            type = "ssh"
            user = "azureuser"
            private_key = tls_private_key.rsakey.private_key_pem
            host = azurerm_public_ip.PubIP.ip_address
        }
  }
    depends_on = [azurerm_linux_virtual_machine.main, local_file.linuxprivatekey, azurerm_public_ip.PubIP]
}