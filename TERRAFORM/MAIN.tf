terraform {
  required_version = ">=1.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.9.1"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = true
}

variable "group_postfix" {
  type = string
}

variable "user_name" {
  type    = string
  default = "demouser"
}

variable "user_password" {
  type    = string
  default = "Azuredemo2020"
}

locals {
  group_name = "AZ2003-${var.group_postfix}"
  location   = "japaneast"
  random_str = "gsd"
  # random_str               = random_string.rid.result
  lab_name                 = "lab"
  lab01_name               = "lab01"
  lab02_name               = "lab02"
  lab03_name               = "lab03"
  lab04_name               = "lab04"
  lab05_name               = "lab05"
  lab05a_name              = "lab05a"
  lab05b_name              = "lab05b"
  lab05c_name              = "lab05c"
  lab06_name               = "lab06"
  lab07_name               = "lab07"
  lab08_name               = "lab08"
  lab09_name               = "lab09"
  lab09a_name              = "lab09a"
  lab09b_name              = "lab09b"
  lab09c_name              = "lab09c"
  lab10_name               = "lab10"
  lab10b_name              = "lab10b"
  lab11_name               = "lab11"
  lab12_name               = "lab12"
  lab12a_name              = "lab12a"
  lab12b_name              = "lab12b"
  lab13_name               = "lab13"
  lab14_name               = "lab14"
  lab15_name               = "lab15"
  lab16_name               = "lab16"
  lab01_name_with_postfix  = "${local.lab01_name}${local.random_str}"
  lab02_name_with_postfix  = "${local.lab02_name}${local.random_str}"
  lab03_name_with_postfix  = "${local.lab03_name}${local.random_str}"
  lab04_name_with_postfix  = "${local.lab04_name}${local.random_str}"
  lab05_name_with_postfix  = "${local.lab05_name}${local.random_str}"
  lab06_name_with_postfix  = "${local.lab06_name}${local.random_str}"
  lab07_name_with_postfix  = "${local.lab07_name}${local.random_str}"
  lab08_name_with_postfix  = "${local.lab08_name}${local.random_str}"
  lab09_name_with_postfix  = "${local.lab09_name}${local.random_str}"
  lab10_name_with_postfix  = "${local.lab10_name}${local.random_str}"
  lab10b_name_with_postfix = "${local.lab10b_name}${local.random_str}"
  lab11_name_with_postfix  = "${local.lab11_name}${local.random_str}"
  lab12_name_with_postfix  = "${local.lab12_name}${local.random_str}"
  lab13_name_with_postfix  = "${local.lab13_name}${local.random_str}"
  lab14_name_with_postfix  = "${local.lab14_name}${local.random_str}"
  lab15_name_with_postfix  = "${local.lab15_name}${local.random_str}"
  lab16_name_with_postfix  = "${local.lab16_name}${local.random_str}"
  vm_size                  = "Standard_B4ms"

  default_tags = {
    environment     = local.group_name
    SecurityControl = "Ignore"
  }
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "azurerm_client_config" "current" {}

resource "random_string" "rid" {
  length  = 3
  special = false
  numeric = false
  upper   = false
}

resource "random_integer" "rint" {
  min = 100
  max = 999
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "rg" {
  name     = local.group_name
  location = local.location

  tags = {
    environment = local.group_name
  }
}

# Demo Resource Group
resource "azurerm_resource_group" "demo" {
  name     = "Demo${var.group_postfix}"
  location = local.location

  tags = local.default_tags
}
