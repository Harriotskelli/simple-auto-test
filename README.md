# simple-auto-test

This script is a simple automation to do the following

provision an Ubuntu 16.04 server
carry out any configuration steps needed to allow login over ssh, securely and disable password based login
Setting up the firewall to only allow ingress on the ssh port and
only to allow password-less (certificate) based login
then display the MOTD including the text "Hello Assurity DevOps”.

This was done in a simple bash script using virtualbox as it was the simplest to set up in a short time
However it could easily be adapted to run in a playbook (some of it at least)
I will put in considerations I had into brackets for things I would have liked to add if I had more time and other details.
(for example using a playbook for this whole exercise would have been optimal but I could not guarantee tool dependancies and I don't currently have an Ansible implementation at home)

# assumptions

You have virtualbox 6.1.16 installed on an Ubuntu Server
(tested working in Ubuntu Desktop 20.04 and Server 18.04)
-1024MB of available memory
-10GB of available space in /

# usage

Make the script executable

chmod +x start.sh

Then run it

sudo ./start.sh

The script will download the ubuntu-16.04.7-server-amd64 iso into the current location of the script
If you already have the iso simply put it in the same directory to avoid re-download 
(You could change the argument to use a different ISO as well)

While start.sh kicks off the virtualbox vm a bulk of the work is done in the ubuntu preseed.
Default root password is set there but not used
Had a few issues with the default preseed causing some Kernal Panics so had to get a fix (Thanks Rob Raymond of StackExchange)
If i was using an anisble playbook for this I would have a lot of the variables I've set in there available to change especially the Kernal Version but also login username, root password, MOTD, ip addresses etc

Once the ISO is downloaded/found the script will set up the VM config with virtualbox
then it will begin the unattended installation (How long this takes had me worried but I'm used to containers and prebuilt images)
after building starts the script will wait for it to show up on ssh (the preseed configures ssh)
It will use virtualbox to hand over the keys then finally connect with the key so you would be connected to it in your terminal.