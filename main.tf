resource "random_pet" "rg_name" {
    prefix = var.resource_group_name_prefix
}

#Create a resource group
resource "azurerm_resource_group" "rg" {
    name = random_pet.rg_name.id
    location = var.resource_group_location
}

#Create a virtual network
resource "azurerm_virtual_network" "VN" {
    name = "myVnet-${random_pet.rg_name.id}"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    address_space = ["10.0.0.0/16"]
}

#Create a subnet
resource "azurerm_subnet" "sub" {
    name = "mySubnet-${random_pet.rg_name.id}"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.VN.name
    address_prefixes = ["10.0.0.0/24"]
}

#Create a Public IP
resource "azurerm_public_ip" "PubIP" {
    name = "myPublicIP-${random_pet.rg_name.id}"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    allocation_method = "Dynamic"
}

#Create network interface
resource azurerm_network_interface "NIC" {
    name = "myNIC-${random_pet.rg_name.id}"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    ip_configuration {
        name = "myNICallocation"
        subnet_id = azurerm_subnet.sub.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.PubIP.id 
    }
}

#Create a network security group
resource "azurerm_network_security_group" "NSG" {
    name = "myNSG-${random_pet.rg_name.id}"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    security_rule {
        name = "SSH"
        priority = "1000"
        source_address_prefix = "*"
        destination_address_prefix = "*"
        source_port_range = "*"
        destination_port_range = "22"
        protocol = "Tcp"
        direction = "Inbound"
        access = "Allow" 
    }

    security_rule {
        name = "HTTP"
        priority = "1001"
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_address_prefix = "*"
        destination_address_prefix = "*"
        source_port_range = "*"
        destination_port_range = "80"
    }
} 

#Create network interface and network security group assocation
resource "azurerm_network_interface_security_group_association" "NIC_NSG" {
    network_interface_id = azurerm_network_interface.NIC.id
    network_security_group_id = azurerm_network_security_group.NSG.id 
}

#Create random number string for storage account name
resource "random_id" "random" {
    keepers = {
        #Create new ID whenever new resource group is created
        resource_group = azurerm_resource_group.rg.name
    }
    byte_length = 8
}


#Create a storage account for boot diagnostics
resource "azurerm_storage_account" "storeacc" {
    name = "sow${random_id.random.hex}"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    account_tier = "Standard"
    account_replication_type = "LRS"
}

#Create RSA SSH key
resource "tls_private_key" "rsakey" {
    algorithm = "RSA"
    rsa_bits = "4096"
}

#Storing Private Key
resource "local_file" "linuxprivatekey" {
  filename = "linuxprivatekey.pem"
  content = tls_private_key.rsakey.private_key_pem
  depends_on = [ tls_private_key.rsakey ]
}

#Passing Custom Data
data "template_file" "cloudinit" {
    template = file("script.sh")
}

#Create a virtual machine
resource "azurerm_linux_virtual_machine" "main" {
    name = "myVM-${random_pet.rg_name.id}"
    computer_name = "azureuser" #This is the hostname of VM, defaults to 'name' if not specified
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    size = "Standard_DS1_v2"
    network_interface_ids = [azurerm_network_interface.NIC.id]
    source_image_reference {
        publisher = "Canonical"
        offer = "0001-com-ubuntu-server-jammy"
        sku = "22_04-lts-gen2"
        version = "latest" 
    }
    custom_data = base64encode(data.template_file.cloudinit.rendered)
    os_disk {
        name = "MyOS-${random_pet.rg_name.id}"
        caching = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    admin_username = "azureuser"
    admin_ssh_key {
        username = "azureuser"
        public_key = file("~/.ssh/id_rsa.pub")
    }  

    provisioner "file" {
        source = "index.html"
        destination = "/var/www/html/index.html"

        connection {
        type = "ssh"
        user = "azureuser"
        private_key = file("~/.ssh/id_rsa.pub")
        host = azurerm_public_ip.PubIP.ip_address
        }
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.storeacc.primary_blob_endpoint
    }
}
