terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.80.0"
    }
  }
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rgname" {
    name = var.rg_name
    location = var.rg_location  
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rgname.name
  location            = azurerm_resource_group.rgname.location
  sku                 = "Premium"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "akscluster" {
  name                = var.aks_name
  location            = azurerm_resource_group.rgname.location
  resource_group_name = azurerm_resource_group.rgname.name
  dns_prefix          = "nextopsaks-dev"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_B2s"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
    dns_service_ip = "10.0.0.10"
    service_cidr = "10.0.0.0/16"
    load_balancer_sku = "standard"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "aks2acr" {
  principal_id                     = azurerm_kubernetes_cluster.akscluster.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

resource "azurerm_mssql_server" "sqlserver" {
  name                = "xxxxxxxxxx"
  resource_group_name = azurerm_resource_group.rgname.name
  location            = azurerm_resource_group.rgname.location
  version             = "12.0"
  administrator_login          = "xxxxxxxxxx"
  administrator_login_password = "xxxxxxxxxx"
}

resource "azurerm_mssql_database" "sqldb" {
  name                = "mhcdb"
  server_id           = azurerm_mssql_server.sqlserver.id
  collation           = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb         = 1
  sku_name            = "Basic"
}