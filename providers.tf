terraform {
    required_version = ">=0.12"

    required_providers {
#Updated azurerm provider
        azurerm = {
            source = "hashicorp/azurerm"
            version = "3.61.0"
        }

        random = {
            source = "hashicorp/random"
            version = "~>3.0"
        }

        tls = {
            source = "hashicorp/tls"
            version = "~>4.0"
        }
    }
}

provider "azurerm" {
    features {}
}