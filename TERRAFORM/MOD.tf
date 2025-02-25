## MOD-CONTAINER
### Azure Container Registry
resource "azurerm_container_registry" "lab" {
  name                = "${local.lab_name}acr${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Premium"
  admin_enabled       = true

  georeplications {
    location                = "East US"
    zone_redundancy_enabled = true
    tags                    = {}
  }
  georeplications {
    location                = "North Europe"
    zone_redundancy_enabled = true
    tags                    = {}
  }

  tags = {
    environment = local.group_name
  }
}

### Azure Container Instance
resource "azurerm_container_group" "lab" {
  name                = "${local.lab_name}-aci-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  dns_name_label      = "${local.lab_name}-aci-${local.random_str}"
  os_type             = "Linux"

  container {
    name   = "hello-world"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  container {
    name   = "sidecar"
    image  = "abc12207/aci-tutorial-sidecar:latest"
    cpu    = "0.5"
    memory = "1.5"
  }

  tags = {
    environment = local.group_name
  }
}

### Azure Container App
resource "azurerm_log_analytics_workspace" "lab" {
  name                = "${local.lab_name}-log-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_container_app_environment" "lab" {
  name                       = "${local.lab_name}-aca-env-${local.random_str}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.lab.id

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_container_app" "lab" {
  name                         = "${local.lab_name}-aca-${local.random_str}"
  container_app_environment_id = azurerm_container_app_environment.lab.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "examplecontainerapp"
      image  = "mcr.microsoft.com/k8se/quickstart:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  tags = {
    environment = local.group_name
  }
}