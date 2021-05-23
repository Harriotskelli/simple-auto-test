#!/bin/bash
VM="ubuntu-16"
OS="Ubuntu_64" 
iso="ubuntu-16.04.7-server-amd64.iso"
hddsize=32768
LocalHOSTIP=127.0.0.1
AccessPORT=2222
username="login"
password="changeme"
TIMEOUT=30

ssh-keygen -t rsa -f rsa -P $password

#check we got iso
if [ ! -f ./$iso ]; then
    curl https://releases.ubuntu.com/16.04.7/$iso -o ./$iso
fi

#set vm details
VBoxManage createvm --name $VM --ostype $OS --register
VBoxManage createhd --filename /VirtualBox/$VM/$VM.vdi --size $hddsize

#set storage peripherals 
VBoxManage storagectl $VM --name "SATA Controller" --add sata --controller IntelAHCI
VBoxManage storageattach $VM --storagectl "SATA Controller" --port 0 --device 0 \
--type hdd --medium /VirtualBox/$VM/$VM.vdi
VBoxManage storagectl $VM --name "IDE Controller" --add ide 
VBoxManage storageattach $VM --storagectl "IDE Controller" --port 0 --device 0 \
--type dvddrive --medium ./$iso

#set memory and nic config
VBoxManage modifyvm $VM --memory 8192 --nic1 nat --natpf1 rule1,tcp,$LocalHOST,$AccessPORT,10.0.2.15,22

#set unattended install details
VBoxManage unattended install $VM \
--iso=./$iso \
--user=$username --full-user-name=name --password=$password \
--install-additions --script-template=./ubuntu_preseed.cfg \
--start-vm=headless 

echo "We're building the VM. Please wait..."
#this can take a while.
sleep 2m

while :; do 
    echo "Waiting for VM to be up..."
    # https://serverfault.com/questions/152795/linux-command-to-wait-for-a-ssh-server-to-be-up
    # https://unix.stackexchange.com/questions/6809/how-can-i-check-that-a-remote-computer-is-online-for-ssh-script-access
    # https://stackoverflow.com/questions/1405324/how-to-create-a-bash-script-to-check-the-ssh-connection
    status=$(ssh -o BatchMode=yes -o ConnectTimeout=5 ${LocalHOST} -p ${AccessPORT} echo ok 2>&1)
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        # this is not really expected unless a key lets you log in
        echo "connected ok"
        break
    fi
    if [ $RESULT -eq 255 ]; then
        # connection refused also gets you here
        if [[ $status == *"Permission denied"* ]] ; then
            # permission denied indicates the ssh link is okay
            echo "server response found"
            break
        fi
    fi
    TIMEOUT=$((TIMEOUT-1))
    if [ $TIMEOUT -eq 0 ]; then
        echo "timed out"
        # error for jenkins to see
        exit 1 
    fi
    sleep 10
done

VBoxManage guestcontrol $VM --username $username --password $password \
copyto rsa.pub --target-directory /home/$username/.ssh/authorized_keys

ssh -i rsa -l $username $LocalHOST -p $AccessPORT