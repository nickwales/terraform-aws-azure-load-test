resource "azurerm_kubernetes_cluster" "consul-test" {
  name                = "consul-test"
  location            = azurerm_resource_group.consul-test.location
  resource_group_name = azurerm_resource_group.consul-test.name
  dns_prefix          = "consul-test"


  default_node_pool {
    name          = "default"
    node_count    = 3
    vm_size       = "standard_d15_v2"
  }

  network_profile {
    network_policy = "azure"
    network_plugin = "azure"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.consul-test.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.consul-test.kube_config_raw

  sensitive = true
}