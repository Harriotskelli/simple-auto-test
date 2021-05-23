#!/bin/bash
VM="ubuntu-16"

#check we got iso
if [ ! -f ./ubuntu-16.04.7-server-amd64.iso ]; then
    curl https://releases.ubuntu.com/16.04.7/ubuntu-16.04.7-server-amd64.iso -o ./ubuntu-16.04.7-server-amd64.iso
fi

#set parameters
VBoxManage createvm --name $VM --ostype "Ubuntu_64" --register
VBoxManage createhd --filename /VirtualBox/$VM/$VM.vdi --size 32768

#set storage peripherals 
VBoxManage storagectl $VM --name "SATA Controller" --add sata --controller IntelAHCI

VBoxManage storageattach $VM --storagectl "SATA Controller" --port 0 --device 0 \
--type hdd --medium /VirtualBox/$VM/$VM.vdi

#TODO had some issues using AHCI as the hdd controller so swapped them, should investigate
VBoxManage storagectl $VM --name "IDE Controller" --add ide 
VBoxManage storageattach $VM --storagectl "IDE Controller" --port 0 --device 0 \
--type dvddrive --medium ./ubuntu-16.04.7-server-amd64.iso

#set memory and nic config
VBoxManage modifyvm $VM --memory 8192 --nic1 nat --natpf1 rule1,tcp,127.0.0.1,2222,10.0.2.15,22

#set unattended install details
VBoxManage unattended install $VM \
--iso=./ubuntu-16.04.7-server-amd64.iso \
--user=login --full-user-name=name --password=changeme \
--script-template=./ubuntu_preseed.cfg \
--start-vm=headless 
