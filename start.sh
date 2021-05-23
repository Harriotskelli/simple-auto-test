#!/bin/bash
VM="ubuntu-16"

if [ ! -f ./ubuntu-16.04.7-server-amd64.iso ]; then
    curl https://releases.ubuntu.com/16.04.7/ubuntu-16.04.7-server-amd64.iso -o ./ubuntu-16.04.7-server-amd64.iso
fi

VBoxManage createvm --name $VM --ostype "Ubuntu_64" --register
VBoxManage createhd --filename /VirtualBox/$VM/$VM.vdi --size 32768
VBoxManage storagectl $VM --name "SATA Controller" --add sata --controller IntelAHCI
VBoxManage storageattach $VM --storagectl "SATA Controller" --port 0 --device 0 \
--type hdd --medium /VirtualBox/$VM/$VM.vdi
VBoxManage storagectl $VM --name "IDE Controller" --add ide
VBoxManage storageattach $VM --storagectl "IDE Controller" --port 0 --device 0 \
--type dvddrive --medium ./ubuntu-16.04.7-server-amd64.iso

VBoxManage modifyvm $VM --memory 8192 --nic1 nat --natpf1 rule1,tcp,127.0.0.1,2222,10.0.2.15,22

VBoxManage unattended install $VM \
--iso=./ubuntu-16.04.7-server-amd64.iso \
--user=admin --full-user-name=name --password=changeme

VBoxManage startvm $VM --type headless