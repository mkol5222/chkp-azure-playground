
resource "azurerm_route_table" "aks-rt" {
  name                          = "aks-rt-tf"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           =  azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false


  route {
    name                   = "to-linux"
    address_prefix         = "10.68.2.0/24"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.68.202.4"
  }

  route {
    name           = "route-to-my-pub-ip"
    address_prefix = "${var.myip}/32"
    next_hop_type  = "Internet"
  }

  dynamic "route" {
    for_each = var.route_through_firewall ? [] : [1]
    content {
      name           = "to-internet"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  }
  dynamic "route" {
    for_each = var.route_through_firewall ? [1] : []
    content {
      name                   = "to-internet"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.68.202.4"
    }
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
}

resource "azurerm_subnet_route_table_association" "aks-rt-to-subnet" {
  subnet_id      = azurerm_subnet.aks-subnet.id
  route_table_id = azurerm_route_table.aks-rt.id
}

