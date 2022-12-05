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

# initialize variables
variable "vm_name" {
    type = string
    description = "is used to set vm hostname and is how terraform identifies this resource"
}

variable "net_name" {
    type = string
    default = "network_1"
    description = "doesn't do anything as terraform isn't managing the virtual network"
}

variable "mac_addr" {
    type = string
    description = "static addresses are assigned based on mac address by ./modules/virtual-network/config.xml"
}

variable "cloudinit_path" {
    type = string
    description = "sets path to any cloud_init.cfg in ./scripts/"
}

# create pool
resource "libvirt_pool" "resource_pool" {
    name = "${var.vm_name}_pool" # used to identify a pool
    type = "dir" # provides the means to manage files in the directory
    path = "/libvirt-images/${var.vm_name}_pool" # where storage and images are saved
}

# create image
resource "libvirt_volume" "resource_image" {
    name = "${var.vm_name}_image.qcow2"
    pool = libvirt_pool.resource_pool.name
    source = "${path.module}/../../downloads/debian-11-genericcloud-amd64.qcow2"
    format = "qcow2"    
}

# add cloudinit disk to pool
resource "libvirt_cloudinit_disk" "commoninit" {
    name = "commoninit.iso"
    pool = libvirt_pool.resource_pool.name
    user_data = data.template_file.user_data.rendered
}

# read cloudinit configuration
data "template_file" "user_data" {
    template = file("${var.cloudinit_path}")
}

# define kvm domain
resource "libvirt_domain" "resource_domain" {
    # name must be unique
    name = "${var.vm_name}_domain"
    memory = "512"
    vcpu = 1
    # add cloud init disk to share user data
    cloudinit = libvirt_cloudinit_disk.commoninit.id 

    # set to use default libvirt network
    network_interface {
        # set network_name here to force vm into desired v-net
        network_name = "${var.net_name}"
        mac = "${var.mac_addr}"
        wait_for_lease = true
    }

    console {
        type = "pty"
        target_type = "serial"
        target_port = "0"
    }

    disk {
        volume_id = libvirt_volume.resource_image.id
    }

    graphics {
        type = "spice"
        listen_type = "address"
        autoport = true
    }
}

output "IPs" {
  value = libvirt_domain.resource_domain.*.network_interface.0.addresses
}