resource "null_resource" "addfile" {
  provisioner "file" {
    source = "index.html"
    destination = "/var/www/html/index.html"
  }

  connection {
    type = "ssh"
    user = "azureuser"
    private_key = file("${local_file.linuxprivatekey.filename}")
    host = "${azurerm_public_ip.PubIP.ip_address}"
    }

    depends_on = [ azurerm_linux_virtual_machine.main, local_file.linuxprivatekey ]
  }
