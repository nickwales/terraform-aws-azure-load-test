resource "azurerm_virtual_network" "consul-test" {
  name                = "consul-test"
  location            = azurerm_resource_group.consul-test.location
  resource_group_name = azurerm_resource_group.consul-test.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name           = "aks"
    address_prefix = "10.0.1.0/24"
    security_group = azurerm_network_security_group.consul-test.id    
  }

  subnet {
    name           = "vm"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.consul-test.id
  }

}


resource "azurerm_network_security_group" "consul-test" {
  name                = "consul-test"
  location            = azurerm_resource_group.consul-test.location
  resource_group_name = azurerm_resource_group.consul-test.name

  security_rule {
    name                       = "consul-test"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

