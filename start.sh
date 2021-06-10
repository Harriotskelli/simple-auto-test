#!/bin/bash
VM="ubuntu-16"
OS="Ubuntu_64" 
iso="ubuntu-16.04.7-server-amd64.iso"
release="16.04.7"
hddsize=32768
LocalHOSTIP=127.0.0.1
AccessPORT=2222
username="login"
password="changeme"
TIMEOUT=60
LOG_FILE="log.log"
RSAname="rsa"

exec 3>&1 1>>${LOG_FILE} 2>&1

echo "Generating a key" 1>&3
ssh-keygen -t rsa -f $RSAname -P $password

#check we got iso
if [ ! -f ./$iso ]; then
	echo "Downloaing the ISO..." 1>&3
    curl https://releases.ubuntu.com/$release/$iso -o ./$iso
fi

echo "setting the VM details" 1>&3
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

echo "Starting the build" 1>&3
#set unattended install details
VBoxManage unattended install $VM \
--iso=./$iso \
--user=$username --full-user-name=name --password=$password \
--install-additions --script-template=./ubuntu_preseed.cfg \
--start-vm=headless 

echo "We're building the VM. Please wait..." 1>&3
#this can take a while.
sleep 3m

while :; do 
    echo "Waiting for VM to be up..." 1>&3
    # https://serverfault.com/questions/152795/linux-command-to-wait-for-a-ssh-server-to-be-up
    # https://unix.stackexchange.com/questions/6809/how-can-i-check-that-a-remote-computer-is-online-for-ssh-script-access
    # https://stackoverflow.com/questions/1405324/how-to-create-a-bash-script-to-check-the-ssh-connection
    status=$(ssh -o BatchMode=yes -o ConnectTimeout=10 ${LocalHOST} -p ${AccessPORT} echo ok 2>&1)
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        # this is not really expected unless a key lets you log in
        echo "connected ok" 1>&3
        break
    fi
    if [ $RESULT -eq 255 ]; then
        # connection refused also gets you here
        if [[ $status == *"Permission denied"* ]] ; then
            # permission denied indicates the ssh link is okay
            echo "server response found" 1>&3
            break
        fi
    fi
    TIMEOUT=$((TIMEOUT-1))
    if [ $TIMEOUT -eq 0 ]; then
        echo "timed out trying again" 1>&3
        # error for automation controller to see
        exit 1 
    fi
    sleep 10
done

echo "Putting the key onto the host" 1>&3
#put the key onto the VM
VBoxManage guestcontrol $VM --username $username --password $password \
copyto rsa.pub --target-directory /home/$username/.ssh/authorized_keys \
|| echo "Failed to put the key onto the host, did the addtions install correctly?" 1>&3

echo "Finally attempt to connect with the key over ssh" 1>&3
ssh -i rsa -l $username $LocalHOST -p $AccessPORT 