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
}

variable "net_name" {
}

variable "mac_addr" {
}

variable "cloudinit_path" {
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
    source = "${path.module}/../../downloads/debian-11-generic-amd64-20220911-1135.qcow2"
    format = "qcow2"    
}

# add cloudinit disk to pool
resource "libvirt_cloudinit_disk" "resource_disk" {
    name = "commoninit.iso"
    pool = libvirt_pool.resource_pool.name
    user_data = data.template_file.data_cloudinit.rendered
}

# read cloudinit configuration
data "template_file" "data_cloudinit" {
    template = file("${var.cloudinit_path}")
}

# define kvm domain
resource "libvirt_domain" "resource_domain" {
    # name must be unique
    name = "${var.vm_name}_domain"
    memory = "1024"
    vcpu = 1
    # add cloud init disk to share user data
    cloudinit = libvirt_cloudinit_disk.resource_disk.id 

    # set to use default libvirt network
    network_interface {
        # set network_name here to force vm into desired v-net
        network_name = "${var.net_name}"
        mac = "${var.mac_addr}"
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