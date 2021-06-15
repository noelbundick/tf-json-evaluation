# Terraform JSON output - Subnet/NSG Investigation 
## Context

* `main.tf` - Terraform configuration w/ a resource group, virtual network with two subnets, and a network security group connected to `subnet1`
* `/plans/subnet-nsg.tfplan` - Terraform plan
* `/plans/subnet-nsg.tfplan.json` - Terraform plan formatted to JSON
* `/graphs/subnet-nsg.graph.json` - Azure resource graph query capturing the resource group after running `terraform apply ./plans/subnet-nsg.tfplan`

## Problem

We using the `terraform show -json [plan-file]` command to generate a JSON representation of the terraform plan. When looking through the JSON output, the expected relationship between the nsg and the connected subnet, `subnet1`, is lost. The output has three main sections that describe the resources: `planned_values`, `resource_changes`, and  `configuration`.

``` json
// /plans/subnet-nsg.tfplan.json
// ...planned_values
 // line 74 - vnet
        {
          "address": "azurerm_virtual_network.vnet1",
          "mode": "managed",
          "type": "azurerm_virtual_network",
          "name": "vnet1",
          "provider_name": "registry.terraform.io/hashicorp/azurerm",
          "schema_version": 0,
          "values": {
            "address_space": [
              "10.0.0.0/16"
            ],
            "bgp_community": null,
            "ddos_protection_plan": [],
            "dns_servers": null,
            "location": "westus2",
            "name": "vnet1",
            "resource_group_name": "josh-test-rg",
            "subnet": [
       // subnet that is associated with the nsg 
              {
                "address_prefix": "10.0.0.0/24",
                "name": "subnet1"
              },
       // subnet that is NOT associated with any nsg
              {
                "address_prefix": "10.0.1.0/24",
                "name": "subnet2",
                "security_group": ""
              }
            ],
            "tags": null,
            "timeouts": null,
            "vm_protection_enabled": false
          }
        }
// ...resource_changes
// line 271 - vnet
        "after_unknown": {
          "address_space": [
            false
          ],
          "ddos_protection_plan": [],
          "guid": true,
          "id": true,
          "subnet": [
      // can see that the first subnet has a security group but doesn't tell us which one
            {
              "id": true,
              "security_group": true
            },
            {
              "id": true
            }
          ]
        },
// ...configuration
// we have information on the vnet and nsg but there is no referrnce to any subnet in the configuration section
```

``` hcl
// main.tf - line 52
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

  subnet {
    address_prefix = "10.0.1.0/24"
    name           = "subnet2"
  }
}
```

## Goal

We would like to be able to see if/any network rules are applied to a specific subnet. This would mean creating a JSON represation that has all the relevant inforamtion from the plan file. Where this information would be available is somewhat unclear. This could mean providing a `"subnets"` array in the `"configuration"` section of the JSON output. This array could contain an `"expressions"` object that `"references"` the `nsg`.  

We have attempted to dive into the terraform source code but have had trouble figuring out how to access and unwrap the properties that are relevant to this issue. We think we have an idea of where to start and below is instructions on how to run terraform command `terraform show -json [plan-file]` in a dev enviroment.

### Run Terraform in Dev Environment

* git clone this repo
* git clone the [forked terraform repo](https://github.com/Joshua-Phelps/terraform/tree/json-investigation) - contains launch file to run against the terraform plan
* change the `"cwd"` in the vscode/launch.json file in the terraform repo to the correct location of the tf-json-evaluation repo on your computer
* start without bugging and verify that the json output is available in the Debug Console
* We were looking at some breakpoints in the `marshalResources` function on line 342 of `/internal/command/jsonconfig/config.go`, but are not confident that this is the correct location to be investigating.  
