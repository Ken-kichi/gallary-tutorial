provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }

  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "gallery_rg" {
  name     = var.name
  location = var.location
}


resource "azurerm_service_plan" "gallery_plan" {
  name                = "gallery_plan"
  resource_group_name = azurerm_resource_group.gallery_rg.name
  location            = azurerm_resource_group.gallery_rg.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_linux_web_app" "galleryapp" {
  name                = "galleryapp${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.gallery_rg.name
  location            = azurerm_service_plan.gallery_plan.location
  service_plan_id     = azurerm_service_plan.gallery_plan.id

  identity {
    type = "SystemAssigned"
  }

 site_config {
    application_stack {
      docker_image_name   = "galleryacrqjoaln.azurecr.io/fastapi-app:latest"
      docker_registry_url = "https://galleryacrqjoaln.azurecr.io"
    }

    container_registry_use_managed_identity = true
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    WEBSITES_PORT                      = "8000"
  }

}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.galleryapp.identity[0].principal_id
}


resource "azurerm_container_registry" "acr" {
  name                = "galleryacr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.gallery_rg.name
  location            = azurerm_resource_group.gallery_rg.location
  sku                 = "Premium"
  admin_enabled       = false

}


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


data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = "gallery-kv${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.gallery_rg.name
  location            = azurerm_resource_group.gallery_rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  purge_protection_enabled = true


  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_linux_web_app.galleryapp.identity[0].principal_id


    secret_permissions = [
      "Get",
      "Set",
      "Delete",
      "List"
    ]

    # 鍵に対する許可（暗号化・署名などに利用）
    key_permissions = [
      "Get",
      "List",
      "Update",
      "Create"
    ]
  }
}

