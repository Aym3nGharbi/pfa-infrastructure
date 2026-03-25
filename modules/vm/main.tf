# Network Interface for the VM
resource "azurerm_network_interface" "vm" {
  name                = "${var.prefix}-vm-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "vm-ip-config"
    subnet_id                     = var.subnet_web_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.3.4"
  }
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "${var.prefix}-vm"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  zone                            = var.zone
  tags                            = var.tags

  network_interface_ids = [
    azurerm_network_interface.vm.id
  ]

  os_disk {
    name                 = "${var.prefix}-vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Cloud-init script — runs on first boot
  # Installs .NET, Nginx, and GitHub Actions runner
  custom_data = base64encode(templatefile("${path.module}/cloud-init.tpl", {
    app_port = var.app_port
  }))

  identity {
    type = "SystemAssigned"
  }
}