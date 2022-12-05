# automatically add terraform-libvirt plugin from terraform.io
terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

# ensure qemu is running first
provider "libvirt" {
    uri = "qemu:///system"
}

# let terraform manage the lifecycle of the virtual network
resource "null_resource" "resource_network" {
	# add provisioners here
	provisioner "local-exec" {
		command = "virsh net-define ${path.module}/config.xml && virsh net-autostart network_1 && virsh net-start network_1"
        interpreter = ["/bin/bash", "-c"]
	}
	
	provisioner "local-exec" {
		when = destroy
		command = "virsh net-undefine network_1 && virsh net-destroy network_1"
	}
}