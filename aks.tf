# resource "azurerm_subnet" "consul-test-aks" {
#   name                 = "consul-test-aks"
#   resource_group_name  = azurerm_resource_group.consul-test.name
#   virtual_network_name = azurerm_virtual_network.consul-test.name
#   address_prefixes     = ["10.0.1.0/24"]
# }

# resource "azurerm_subnet_network_security_group_association" "consul-test-aks" {
#   subnet_id                 = azurerm_subnet.consul-test-aks.id
#   network_security_group_id = azurerm_network_security_group.consul-test.id
# }

resource "azurerm_kubernetes_cluster" "consul-test" {
  name                = "consul-test"
  location            = azurerm_resource_group.consul-test.location
  resource_group_name = azurerm_resource_group.consul-test.name
  dns_prefix          = "consul-test"


  default_node_pool {
    name          = "default"
    node_count    = 3
    vm_size       = "standard_d15_v2"
    #pod_subnet_id = azurerm_subnet.consul-test-aks.id
    #vnet_subnet_id = azurerm_virtual_network.consul-test.subnet.*.id[0]
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

resource "azurerm_kubernetes_cluster_node_pool" "win101" {
 # availability_zones    = [1, 2, 3]
  enable_auto_scaling   = true
  kubernetes_cluster_id = azurerm_kubernetes_cluster.consul-test.id
  max_count             = 3
  min_count             = 1
  mode                  = "User"
  name                  = "win101"
  #orchestrator_version  = data.azurerm_kubernetes_service_versions.current.latest_version
  os_disk_size_gb       = 30
  os_type               = "Windows" # Default is Linux, we can change to Windows
  vm_size               = "Standard_DS2_v2"
  priority              = "Regular"  # Default is Regular, we can change to Spot with additional settings like eviction_policy, spot_max_price, node_labels and node_taints
  #vnet_subnet_id        = azurerm_subnet.aks-default.id 
  node_labels = {
    "nodepool-type" = "user"
    "environment"   = "production"
    "nodepoolos"    = "windows"
    "app"           = "dotnet-apps"
  }
  tags = {
    "nodepool-type" = "user"
    "environment"   = "production"
    "nodepoolos"    = "windows"
    "app"           = "dotnet-apps"
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