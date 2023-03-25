

# resource "azurerm_subnet" "consul-test-vm" {
#   name                 = "internal"
#   resource_group_name  = azurerm_resource_group.consul-test.name
#   virtual_network_name = azurerm_virtual_network.consul-test.name
#   address_prefixes     = ["10.0.2.0/24"]
# }

# resource "azurerm_subnet_network_security_group_association" "consul-test-vm" {
# #  subnet_id                 = azurerm_virtual_network.consul-test.vm.id
#   subnet_id                 = azurerm_subnet.vm.id
#   network_security_group_id = azurerm_network_security_group.consul-test.id
# }

resource "azurerm_public_ip" "consul-test-public" {
  name                = "consult-test-public-ip"
  resource_group_name = azurerm_resource_group.consul-test.name
  location            = azurerm_resource_group.consul-test.location
  allocation_method   = "Dynamic"
}

# resource "azurerm_network_interface" "consul-test-public" {
#   name                = "consul-test"
#   location            = azurerm_resource_group.consul-test.location
#   resource_group_name = azurerm_resource_group.consul-test.name

#   ip_configuration {
#     name                          = "public"
#     public_ip_address_id = azurerm_public_ip.public_ip.id
#     #private_ip_address_allocation = "Dynamic"
#   }
# }

resource "azurerm_network_interface" "consul-test" {
  name                = "consul-test"
  location            = azurerm_resource_group.consul-test.location
  resource_group_name = azurerm_resource_group.consul-test.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_virtual_network.consul-test.subnet.*.id[1]
    public_ip_address_id = azurerm_public_ip.consul-test-public.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "consul-test-vm" {
  name                = "consul-test-vm"
  resource_group_name = azurerm_resource_group.consul-test.name
  location            = azurerm_resource_group.consul-test.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.consul-test.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}