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
  length = 6
  upper = false
  special = false
}

resource "azurerm_linux_web_app" "galleryapp" {
  name                = "galleryacr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.gallery_rg.name
  location            = azurerm_service_plan.gallery_plan.location
  service_plan_id     = azurerm_service_plan.gallery_plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {}
}

resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = azurerm_storage_account.gallery_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
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


data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                = "gallery-kv${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.gallery_rg.name
  location                 = azurerm_resource_group.gallery_rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  purge_protection_enabled = true


  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id


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

