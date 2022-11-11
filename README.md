# provision local qemu-kvm vm with terraform

> NOTE: I wanted to learn how to quickly and automatically deploy vm's on my proxmox host, but at the same time I really didn't want to have to learn terraform while learning proxmox. So, I figured I'd learn the basics of terraform here, and then go take a crack at proxmox-terraform integration later. 

How to use Terraform to create a small-scale Cloud Infrastructure | by Nitesh | ITNEXT
https://itnext.io/how-to-use-terraform-to-create-a-small-scale-cloud-infrastructure-abf54fabc9dd#bf8f
> *I got as far as Chapter "9. Installing Docker and Terraform provider for docker" and stopped right before it. Since, I had learnt all I wanted regarding the basics of terraform provisioning from this guide. Now that I have the basics down and a good grasp of everything cloud-init, cloud-images, and terraform scripting. I think it's time I got to work on my proxmox server w/ ansible & friends...*

Click [here](provision%20local%20qemu-kvm%20vm%20with%20terraform.md#^b9c02a) to jump to the latest log I wrote for this guide

simple way to provision and manage docker containers? : devops
https://www.reddit.com/r/devops/comments/p1aeyg/simple_way_to_provision_and_manage_docker/
> Ansible is built for configuration management, while technically being able to provision if it has access to the API. The better tool for provisioning is terraform. So in this case you would use both. I didn't try out terraform yet, but ansible is certainly a great piece of software and worth learning. It is also designed to be as simple as possible.

> Maybe the answer is organizing containers in docker-compose files. It's not an orchestration tool, is more a way to have your deployments/containers versioned



Test support for the appropriate CPU
```shell
lscpu | grep Virtualization
	Virtualization:                  VT-x
# In case of linux machine, instruct physical machine's KVM to enable nested virtualisation (only possible with VT-x).
sudo rmmod kvm-intel && sudo modprobe kvm_intel nested=1
# If the output prints ‘Y’ or ‘1’, it is safe to proceed 
cat /sys/module/kvm_intel/parameters/nested
	Y
```


Download Terraform for Linux 64-bit by going to www.terraform.io/ and pressing on AMD64 under LINUX BINARY DOWNLOAD
```shell
wget https://releases.hashicorp.com/terraform/1.3.2/terraform_1.3.2_linux_amd64.zip -p ~/Downloads/
cd ~/Downloads 
unzip terraform_1.3.2_linux_amd64.zip
sudo mv terraform /usr/local/bin/terraform
# sudo pacman -S terraform # works - but just download the binary, its easy af
terraform -v

```

**TANGENT** - setup simple terraform project & run some tests
```
mkdir terraform-testbench && cd terraform-testbench/
git init && git add . && git commit -m "v0.1"
terraform init && terraform apply && terraform destroy
```

install kvm packages - if you are wondering where `virt-top` equivalanet is, it's called virst and comes bundled with libvirt
```shell
# sudo apt -y install qemu-kvm libvirt-bin virt-top libguestfs-tools virtinst bridge-utils
sudo pacman -Syyu
sudo pacman -S qemu-base libvirt libguestfs virt-install bridge-utils
```

**TANGENT** - install `linux` kernel cause `vhost_run` isn't a module on `linux-surface` kernel - rip touchscreen - prior experience with compiling kernel on void should help you **TODO** compile kernel with `vhost_run=m` :C 

**TODO** oh hey i need help with getting my `mwifiex_pcie` drivers to support the `set_wiphy_netns` command as well!!!
```
sudo modprobe vhost_net
# modprobe: FATAL: Module vhost_net not found in directory /lib/modules/...
uname -r # find current kernel
find /boot/vmli* # list possible kernels
sudo pacman -S linux linux-headers # install

# cause ~~`GRUB_DEFAULT=saved GRUB_SAVEDEFAULT=true GRUB_DISABLE_SUBMENU=y`~~ can't work cause grub cannot write to a /boot partition that is btrfs 
# **TODO** on future partion maps (this + void exemplar):
	# /dev/nvme0n1p1 (512M) mounted on /boot/efi as vfat
	# /dev/nvme0n1p2 (512M) mounted on /boot as ext4
sudo vim /etc/default/grub
---	GRUB_DEFAULT=0
+++	GRUB_DEFAULT=4

# 0: linux-surface, 1: fallback, 2: linux-lts, 3: fallback, 4: linux, 5: fallback
update-grub
sudo reboot
uname -r
```

Enable the `vhost_net` kernel module to allow `libvirt` to directly call into subsystems instead of using calls from userspace to increase VM performance.
```shell
sudo modprobe vhost_net
sudo lsmod | grep vhost
	vhost_net              36864  0
	tun                    61440  1 vhost_net
==	vhost                  57344  1 vhost_net==
	vhost_iotlb            16384  1 vhost
	tap                    28672  1 vhost_net

sudo systemctl enable libvirtd # start a service at boot
sudo systemctl start libvirtd # start service now
sudo systemctl status libvirtd # service status


# **NOT** using `virt-manager` from step 'install kvm' substep '8' - i dont want gui
```

**DEPRECATED** - most commands here aren't necesary since provider is autoinstalled by terraform 
```shell
# ====================================================================
#  START - DEPRECATED 
# ====================================================================

# **DEPRECATED** install go INSTEAD add terraform provider to $PATH
# wget https://dl.google.com/go/go1.19.2.linux-amd64.tar.gz -p ~/Downloads/
# sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.19.2.linux-amd64.tar.gz
vim ~/.bashrc
	# export PATH=$PATH:/usr/local/go/bin # path for golang
	export PATH=$PATH:/usr/lib/go/bin # terraform provider binary
	# export GOPATH=/usr/lib/go # prob for compiling providers
source ~/.bashrc
# echo $GOPATH


# **DEPRECATED** - compile build 
# wait, isn't this installing *-git version, if `build and test` is `faiing` then obviously u can't do compile - **NOTE** try downloading latest release instead
# cd terraform-provider-libvirt
# sudo mkdir -p $GOPATH/src/github.com/dmacvicar/
# cd $GOPATH/src/github.com/dmacvicar/
# sudo git clone https://github.com/dmacvicar/terraform-provider-libvirt.git 
# sudo make install
# cd $GOPATH/bin/
# ./terraform-provider-libvirt -version

# install latest release instead
# wget https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.6.14/terraform-provider-libvirt_0.6.14_linux_amd64.zip
# unzip terraform-provider-libvirt_0.6.14_linux_amd64.zip
# sudo mkdir -p $GOPATH/bin
# sudo mv /tmp/terraform-libvirt/terraform-provider-libvirt_v0.6.14 $GOPATH/bin/terraform-provider-libvirt
# cd $GOPATH/bin && ./terraform-provider-libvirt -version

# add provider as plugin
cd ~/.terraform.d/ && ls
mkdir ~/.terraform.d/plugins
# sudo ln -s /usr/lib/go/bin/terraform-provider-libvirt ~/.terraform.d/plugins/

# ==================================================================
#  END - DEPRECATED SINCE PROVIDER IS AVAILABLE FOR AUTOINSTALLATON 
# ==================================================================
```

add `$USER` to libvirt and kvm groups. btw `local = $USER`
```shell
sudo usermod -aG libvirt,kvm local
su local
id -nG | grep 'libvirt\|kvm'
```

disable QEMU SELinux but leave SELinux for host enabled
```shell
sudo vim /etc/libvirt/qemu.conf
	security_driver = "none" ← #security_driver = "selinux" 	
sudo systemctl restart libvirtd
```

terraform project stuff - bassically just write some configs, make some directories basically, download some repos, and run a few commands

```shell
# normally autocreated, i'll try making just `/libvirt-images` for now
# **NOTE** `/libvirt-images` seemed insignificat - but might be crucial to proper perms for VMs :O

sudo mkdir -p /libvirt-images/testbench-pool 

mkdir -p ~/kvm-testbench/downloads 
cd ~/kvm-testbench/ && touch libvirt.tf # CHECK TESTBENCH FOR TEMPLATES
cd ~/kvm-testbench/ && touch cloud_init.cfg # CHECK TESTBENCH FOR TEMPLATES
	# '#cloud-config' on line 1 
	# call from .tf to cloud_init.cfg
	# cat ~/.ssh/testbench.pub 

	# How To Use Cloud-Config For Your Initial Server Setup | DigitalOcean
	# https://www.digitalocean.com/community/tutorials/
	# how-to-use-cloud-config-for-your-initial-server-setup
	# #troubleshooting
```
> the “How AWS Firecracker works” post mentions “virtio-fs, which allows efficient sharing of files and directories between hosts and guest. This way, a directory containing the guests’ file system can be on the host, much like how Docker works.” the kernel docs on virtio-fs 😳 
> -https://jvns.ca/blog/2021/01/23/firecracker--start-a-vm-in-less-than-a-second/

download cloud-image (fast iso) and make ssh key pair
```shell
cd ~/kvm-testbench/downloads
# wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
wget http://cloud.debian.org/images/cloud/bullseye/20220911-1135/debian-11-generic-amd64-20220911-1135.qcow2

ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/testbench -C ###############.###@gmail.com
# press `enter` twice for no passphrase
cd ~/.ssh/ && chmod +x testbench.pub && mv testbench testbench.key
ls -al testbench* # check perms for read/write access
	-rw------- 1 local local 419 Oct  6 21:45 testbench.key
	-rwxr-xr-x 1 local local 111 Oct  6 21:45 testbench.pub
```

**TANGENT** -  manually create bridge network to check commands work and increased familiarity
```shell
echo $(virsh net-dumpxml default) > /data/terraform/kvm-testbench/libvirt_network_config.xml
vim /data/terraform/kvm-testbench/libvirt_network_config.xml # see templates
sudo virsh net-define libvirt_network_config.xml
sudo virsh net-start terraform_ne
sudo virsh net-list --all

# to force a vm to use the new virtual network:
resource "libvirt_domain" "test-domain" {
    network_interface {
        # set network_name here to force vm into v-net
	network_name = "terraform_net"
    }

terraform init
terraform apply
sudo virsh net-dhcp-leases terraform_net
# test network by trying to ssh into vm and by requesting a response from picalc server

terraform destroy
virsh net-undefine picalc_net
virsh net-destroy picalc_net
```

/data/terraform/kvm-testbench/modules/network
now let terraform handle the lifecycle of your virtual bridge network
```
mkdir -p /data/terraform/kvm-testbench/modules/network/
mv /data/terraform/kvm-testbench/libvirt_network_config.xml /data/terraform/kvm-testbench/modules/network/config.xml
touch /data/terraform/kvm-testbench/modules/network/picalc_net # see template

cd /data/terraform/kvm-testbench/modules/network/
terraform init
sudo terraform apply
virsh net-list --all
# test network by trying to ssh into vm and by requesting a response from picalc server
sudo terraform destroy
```

set static ip addresses via mac address for vms

### 9. Installing Docker and Terraform provider for docker

^b9c02a

most of the work to get up to here was writing code, I've only documented some of the commands I had to use and tangents I went on here.

## the poor mans dashboard
```shell
# ================================
#  IMPORTANT COMMANDS CHEATSHEAT
# ================================

# terraform commands 
terraform init
sudo terraform apply -auto-approve
sudo terraform destroy -auto-approve

terraform state list
sudo terraform apply -target=
sudo terraform destroy -target=

# main thread
sudo virsh list --all 
sudo virsh console 

sudo virsh net-dhcp-leases default 
curl 192.168.122.:8080/PiCalc/100
ssh -i ~/.ssh/testbench.key local@192.168.122.



# virsh - help + list vm
virsh help | grep network
man virsh | grep network
sudo virsh list --all

# pool stack
sudo virsh pool-list --all
# if showing same, everything is gucci
	sudo virsh vol-list testbench-pool
	sudo ls /libvirt-images/testbench-pool/

# network stack
sudo virsh net-list --all
sudo virsh net-dhcp-leases default # 192.168.122.36/24
# ping 192.168.122.36 # 0% packet loss OWO
ssh -i ~/.ssh/testbench.key local@192.168.122.126

# How to destroy one specific resource with TF file? · Issue #12917 · hashicorp/terraform
# https://github.com/hashicorp/terraform/issues/12917

# I would like to run terraform only for a specific resource - Stack Overflow
# https://stackoverflow.com/questions/46762047/i-would-like-to-run-terraform-only-for-a-specific-resource
```

![](https://miro.medium.com/max/720/1*aH2zX5wNebbhOZvEkLymJg.png)

## finding virsh commands
nice I also have a network defined but it doesn't appear in the list (i want to know the name I have to undefine). How could I list it ? edit : nvm it's `net-list` –ChiseledAbs

`virsh net-list --all`. `virsh help` gives a list of all the commands, so things like `virsh help | grep network` produces a list of network related commands; `virsh net-list` was one of them, and (just as with `virsh list`) you need `--all` to show inactive networks as well. –Stephen Harris

virtual machine - How to list domains in virsh? - Unix & Linux Stack Exchange
https://unix.stackexchange.com/questions/300113/how-to-list-domains-in-virsh

---

## debugging cloud-init
```shell
# on master
sudo pacman -S cloud-init cloud_init.cfg

# debugging `cloud_init.cfg` for valid yaml syntax
cloud-init schema --config-file /data/terraform/kvm-testbench/cloud_init.cfg
```

```shell
# on slave
# update + upgrade + install = 140s
# update + install = 65s
# install = 
# sudo apt-get install cloud-init

# sort and print events based on highest time cost
cloud-init analyze blame -i /var/log/cloud-init.log

# organize events into stages and substages and print time cost next to each event
cloud-init analyze show -i /var/log/cloud-init.log

# read through vm init logs - pretty easy to read actually
sudo vim /var/log/cloud-init-output.log
```

Debugging cloud-init — cloud-init 22.3 documentation
https://cloudinit.readthedocs.io/en/latest/topics/debugging.html

---

You can usually find some good information about what happened by using grep to search these files.
  - `/var/log/cloud-init.log` - cloud-init process logs
  - `/var/log/cloud-init-output.log` - vm initialization process logs

If cannot log into the server you created because of some configuration problems - destroy the server and start again with a temporarily set up root password 
```
#cloud-config
chpasswd:
  list: |
    root:yourpassword
  expire: False
```

How To Use Cloud-Config For Your Initial Server Setup | DigitalOcean
https://www.digitalocean.com/community/tutorials/how-to-use-cloud-config-for-your-initial-server-setup

## **TANGENTS** debugging - mostly useless but makes similar problems go by super fast with a reference
**Error** error while starting the creation of CloudInit's ISO image: exec: "mkisofs": executable file not found in $PATH
```shell
# fixed by installing mkisofs package: `apk add cdrkit`
# search on `https://archlinux.org/packages/` for `cdrkit` gave `cdrtools`
sudo pacman -S cdrtools
```

**Error**: storage pool 'debian-pool' already exists - but `virsh pool-list` didn't show anything but then I looked at the docs at `https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/virtualization_administration_guide/delete-lvm-storage-pool-virsh` and realised that their commands have `#` indicating root/sudo :facepalm:
```shell
sudo virsh pool-list
 Name          State    Autostart
-----------------------------------
 debian-pool   active   yes
	 
sudo virsh pool-destroy debian-pool
Pool debian-pool destroyed

# sudo virsh pool-delete debian-pool
```

**ERROR**: failed to remove pool '/opt/libvirt-images/debian-pool': Directory not empty
might be because `/opt/` requiring sudo - try `/`
```shell
sudo rm -rf /opt/libvirt-images/debian-pool/

sudo virsh pool-undefine debian-pool
Pool debian-pool has been undefined
sudo virsh pool-list
 Name   State   Autostart
---------------------------
```

**Error**: error creating libvirt domain: Requested operation is not valid: network 'default' is not active
read the error a couple times, looked through code around line indicated, didnt see anything wrong - searched it up: https://www.xmodulo.com/network-default-is-not-active.html - learnt i could try starting it
```shell
sudo virsh net-list --all
 Name      State      Autostart   Persistent
----------------------------------------------
 default   inactive   no          yes

sudo virsh net-start default

# https://libvirt.org/sources/virshcmdref/html/sect-net-autostart.html
# sudo virsh net-autostart --network default --enable
# error: command 'net-autostart' doesn't support option --enable
# man virsh | grep net-autostart
sudo virsh net-autostart default # enable autostart
# sudo virsh net-autostart default --disable # disable autostart
```

**Error**: error defining libvirt domain: operation failed: domain 'testbench-vm' already exists with uuid 1855f3b7-6707-4e0c-b050-e9c5ac83c2ea
```shell
# https://unix.stackexchange.com/questions/300113/how-to-list-domains-in-virsh
# https://www.cyberciti.biz/faq/howto-linux-delete-a-running-vm-guest-on-kvm/
sudo virsh list --all
sudo virsh -c qemu:///system list --all
Id   Name             State
---------------------------------
 -    test-vm-debian   shut off
 -    testbench-vm     shut off

# if "running" 
	# sudo virsh shutdown VM_NAME`
	# sudo virsh destroy VM_NAME
# if "shut off"
	sudo virsh undefine VM_NAME
```



How to use Terraform to create a small-scale Cloud Infrastructure | by Nitesh | ITNEXT
https://itnext.io/how-to-use-terraform-to-create-a-small-scale-cloud-infrastructure-abf54fabc9dd#e6ed

GitHub - dmacvicar/terraform-provider-libvirt: Terraform provider to provision infrastructure with Linux's KVM using libvirt
https://github.com/dmacvicar/terraform-provider-libvirt/

![linux_file_hierarchy](https://i.gzn.jp/img/2007/09/26/Linuxstrusture/linux_file_structure.jpg)

Linux file system hierarchy v1.0 - blackMORE Ops
https://www.blackmoreops.com/2015/02/14/linux-file-system-hierarchy/

Cleaning up a Terraform state file — the right way! | by Karl Cardenas | FAUN Publication
https://faun.pub/cleaning-up-a-terraform-state-file-the-right-way-ab509f6e47f3
> **TODO** looks important - try to understand properly
