terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "josh-test-rg"
  location = "westus2"
}

resource "azurerm_public_ip" "pip1" {
  name                = "pip1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_lb" "lb1" {
  name                = "lb1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "default"
    public_ip_address_id = azurerm_public_ip.pip1.id
  }
}

resource "azurerm_network_security_group" "nsg1" {
  name                = "nsg1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    access                     = "allow"
    description                = "value"
    destination_address_prefix = "*"
    destination_port_range     = "80"
    direction                  = "inbound"
    name                       = "allow http"
    priority                   = 100
    protocol                   = "tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
  }

  security_rule {
    access                     = "allow"
    description                = "value"
    destination_address_prefix = "*"
    destination_port_range     = "443"
    direction                  = "inbound"
    name                       = "allow https"
    priority                   = 110
    protocol                   = "tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
  }
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  subnet {
    address_prefix = "10.0.0.0/24"
    name           = "subnet1"
    security_group = azurerm_network_security_group.nsg1.id
  }
}
