# simple-auto-test

This script is a simple automation to do the following

provision an Ubuntu 16.04 server
carry out any configuration steps needed to allow login over ssh, securely and disable password based login
Setting up the firewall to only allow ingress on the ssh port and
only to allow password-less (certificate) based login
then display the MOTD including the text "Hello Assurity DevOps”.

This was done in a simple bash script using virtualbox as it was the simplest to set up in a short time
However it could easily be adapted to run in a playbook
I will put in considerations I had into brackets for things I would have liked to add if I had more time and other details.
(for example using a playbook for this whole exercise would have been optimal but I could not guarrentee tool dependancies and I don't currently have an Ansible implementation at home)

# assumptions

You have virtualbox installed on an ubuntu server later than 19
Your virtualbox installtion is not missing the unattendedtemplates folder from /usr/share/virtualbox like mine was


# usage

Make the script executable

chmod +x start.sh

Then run it

sudo ./start.sh

The script will download the ubuntu-16.04.7-server-amd64 iso into the current location of the script
If you already have the iso simply put it in the same directory to avoid re-download 
(Would have liked more controlled data entry like specifing iso and install location)

