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

    tags = local.default_tags
  }
  georeplications {
    location                = "North Europe"
    zone_redundancy_enabled = true

    tags = local.default_tags
  }

  tags = local.default_tags
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

  tags = local.default_tags
}

### Azure Container App
resource "azurerm_log_analytics_workspace" "lab" {
  name                = "${local.lab_name}-log-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.default_tags
}

resource "azurerm_container_app_environment" "lab" {
  name                       = "${local.lab_name}-aca-env-${local.random_str}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.lab.id

  tags = local.default_tags
}

resource "azurerm_container_app_environment_storage" "lab" {
  name                         = "labacavolume"
  container_app_environment_id = azurerm_container_app_environment.lab.id
  account_name                 = azurerm_storage_account.lab.name
  share_name                   = azurerm_storage_share.lab.name
  access_key                   = azurerm_storage_account.lab.primary_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app" "lab" {
  name                         = "${local.lab_name}-aca-app-${local.random_str}"
  container_app_environment_id = azurerm_container_app_environment.lab.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "examplecontainerapp"
      image  = "mcr.microsoft.com/k8se/quickstart:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      volume_mounts {
        name = "azure-files-volume"
        path = "/mnt/fileshare"
      }

      volume_mounts {
        name = "ephemeral-volume"
        path = "/mnt/temp"
      }
    }

    volume {
      name         = "azure-files-volume"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.lab.name
    }

    volume {
      name         = "ephemeral-volume"
      storage_type = "EmptyDir"
    }
  }

  tags = local.default_tags
}

# Azure Storage Account
resource "azurerm_storage_account" "lab" {
  name                     = "${local.lab_name}stor${local.random_str}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.default_tags
}

# Azure Storage file share intergration with ACA volume
resource "azurerm_storage_share" "lab" {
  name                 = "labshare${local.random_str}"
  storage_account_name = azurerm_storage_account.lab.name
  quota                = 50
}
