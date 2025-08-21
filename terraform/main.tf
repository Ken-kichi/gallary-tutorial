provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }

  subscription_id = var.subscription_id
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

data "azurerm_client_config" "current" {}

# リソースグループ
resource "azurerm_resource_group" "gallery_rg" {
  name     = var.name
  location = var.location
}

# App Service　Plan
resource "azurerm_service_plan" "gallery_plan" {
  name                = "gallery_plan"
  resource_group_name = azurerm_resource_group.gallery_rg.name
  location            = azurerm_resource_group.gallery_rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# App Service
resource "azurerm_linux_web_app" "galleryapp" {
  name                = "galleryapp${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.gallery_rg.name
  location            = azurerm_service_plan.gallery_plan.location
  service_plan_id     = azurerm_service_plan.gallery_plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    container_registry_use_managed_identity = true

    application_stack {
      docker_image_name   = "fastapi-app:latest"
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
    }
  }
}


resource "azurerm_linux_web_app" "frontapp" {
  name                = "frontapp${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.gallery_rg.name
  location            = azurerm_service_plan.gallery_plan.location
  service_plan_id     = azurerm_service_plan.gallery_plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    container_registry_use_managed_identity = true

    application_stack {
      docker_image_name   = "nextjs-app:latest"
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
    }
  }
}


# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "galleryacr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.gallery_rg.name
  location            = azurerm_resource_group.gallery_rg.location
  sku                 = "Basic"
  admin_enabled       = true

}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.galleryapp.identity[0].principal_id
}

resource "azurerm_role_assignment" "acr_pull_frontend" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.frontapp.identity[0].principal_id
}

# Storage Account
resource "azurerm_storage_account" "gallery_storage" {
  name                     = "galleryst${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.gallery_rg.name
  location                 = azurerm_resource_group.gallery_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "images" {
  name                  = "images"
  storage_account_id    = azurerm_storage_account.gallery_storage.id
  container_access_type = "blob"
}

resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = azurerm_storage_account.gallery_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_web_app.galleryapp.identity[0].principal_id
}

