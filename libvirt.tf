# ~/kvm-testbench/libvirt
# automatically add terraform-libvirt plugin from terraform.io
terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
    uri = "qemu:///system"
}

# create pool
resource "libvirt_pool" "testbench" {
    name = "testbench-pool" # used to identify a pool
    type = "dir" # provides the means to manage files in the directory
    path = "/libvirt-images/testbench-pool" # where storage and images are saved
}

# create image
resource "libvirt_volume" "image-qcow2" {
    name = "testbench-amd64.qcow2"
    pool = libvirt_pool.testbench.name
    source = "${path.module}/downloads/debian-11-generic-amd64-20220911-1135.qcow2"
    format = "qcow2"    
}

# add cloudinit disk to pool
resource "libvirt_cloudinit_disk" "commoninit" {
    name = "commoninit.iso"
    pool = libvirt_pool.testbench.name
    user_data = data.template_file.user_data.rendered
}

# read the configuration
data "template_file" "user_data" {
    template = file("${path.module}/cloud_init.cfg")
}

# define kvm domain
resource "libvirt_domain" "test-domain" {
    # name must be unique
    name = "testbench-vm"
    memory = "1024"
    vcpu = 1
    # add cloud init disk to share user data
    cloudinit = libvirt_cloudinit_disk.commoninit.id 

    # set to use default libvirt network
    network_interface {
        network_name = "default"
    }

    console {
        type = "pty"
        target_type = "serial"
        target_port = "0"
    }

    disk {
        volume_id = libvirt_volume.image-qcow2.id
    }

    graphics {
        type = "spice"
        listen_type = "address"
        autoport = true
    }
}