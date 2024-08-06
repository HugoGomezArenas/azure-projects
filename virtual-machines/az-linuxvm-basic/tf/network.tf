
locals {
  vm_inbound_ports_map = {
    "100" : "80", 
    "110" : "443",
    "120" : "22"
  } 
}


resource "azurerm_virtual_network" "vnet" {
  name                = "${local.resource_name_prefix}-${var.vnet_name}"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags   
}


resource "azurerm_subnet" "vm_subnet" {
  name                 = "${azurerm_virtual_network.vnet.name}-${var.vm_subnet_name}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.vm_subnet_address
}


# Create Network Security Group (NSG)
resource "azurerm_network_security_group" "vm_subnet_nsg" {
  name                = "${azurerm_subnet.vm_subnet.name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Associate the NSG and the subnet 
resource "azurerm_subnet_network_security_group_association" "vm_subnet_nsg_associate" {
  depends_on = [ azurerm_network_security_rule.vm_nsg_rule_inbound ]
  subnet_id = azurerm_subnet.vm_subnet.id
  network_security_group_id = azurerm_network_security_group.vm_subnet_nsg.id
}

resource "azurerm_network_security_rule" "vm_nsg_rule_inbound" {
  for_each                    = local.vm_inbound_ports_map
  name                        = "Rule-Port-${each.value}"
  priority                    = each.key
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value 
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vm_subnet_nsg.name
}

