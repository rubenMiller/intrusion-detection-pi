#!/bin/bash
# set -x # Debugging: Print command before printing
# Exit on error
set -e

# Read ip of IDS-Pi
read -p "Please enter the IP-Address of the IDS-PI: " pi_ip

echo "Installing requirements... "
# we need to get the nameserver, before installing systemd-resolved
old_dns="$(cat /etc/resolv.conf |grep nameserver | cut -f 2 -d ' ')"
# Requirements: smbclient, 
sudo apt update
sudo apt install smbclient iptables iptables-persistent sudo acl systemd-resolved aide #-y can be added to automate
echo "Done!"
echo 

# Username of the IDS-PI
pi_user="ids-pi"

echo "Generating user '$pi_user'... "
# Generate user for the PI

sudo useradd -m -s /bin/bash -N -G sudo $pi_user
sudo usermod -L $pi_user  # Locks the account

# Give him some permissions
sudo pi_user=$pi_user bash -c 'echo "$pi_user ALL = NOPASSWD: /usr/bin/aide" >> /etc/sudoers'
sudo pi_user=$pi_user bash -c 'echo "$pi_user ALL = NOPASSWD: /usr/bin/dpkg -V" >> /etc/sudoers'
sudo pi_user=$pi_user bash -c 'echo "$pi_user ALL = NOPASSWD: /bin/chown -R $pi_user /home/$pi_user/*" >> /etc/sudoers'

sudo -u $pi_user mkdir /home/$pi_user/aide/
sudo setfacl -m $pi_user:r-x /home/$pi_user/aide/
echo "Done!"
echo 

echo "Generating config for pi..."

# Generate aide-config file
aide_config=/home/$pi_user/aide/aide.conf
echo -e "# The aide-config file\n# Please fill according to your system." > $aide_config
vim $aide_config

# Generate config-file
config_file="config-$(hostname -f)"
echo "Hostname=$(hostname -f)" > $config_file
echo "IP=$(ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+')" >> $config_file # IP Address, used to connect to the Internet
    # From: https://stackoverflow.com/questions/21336126/linux-bash-script-to-extract-ip-address
echo "Fingerprint=$(ssh-keyscan -t ed25519 127.0.0.1 | cut -f 2,3 -d ' ')" >> $config_file



# Copy config to Pi using smbclient (see requirements)
smbclient //"$pi_ip"/"configs" -U "$pi_user"%"nG4AghLw" -c "put $config_file"
smbclient //"$pi_ip"/"configs" -U "$pi_user"%"nG4AghLw" -c "put $aide_config"

# Remove temp file
rm $config_file

echo "Done!"
echo 

echo "Adding pi's ssh-key..."
# Get public SSH-Key of Pi
smbclient //"$pi_ip"/"pi-public" -U "$pi_user"%"nG4AghLw" -c "get id_rsa.pub"
sudo -u $pi_user mkdir -p /home/$pi_user/.ssh/
sudo sh -c "cat id_rsa.pub >> /home/$pi_user/.ssh/authorized_keys"
rm id_rsa.pub

echo "Done!"
echo 

echo "Configuring AIDE..."
smbclient //"$pi_ip"/"pi-public" -U "$pi_user"%"nG4AghLw" -c "get aide.conf"
sudo mv aide.conf /home/$pi_user/aide/aide.conf
sudo chown $pi_user /home/$pi_user/aide/*

echo "Done!"
echo 

echo "Setting up network IDS..."
# Configure IPTables to clone all incoming and outgoing pakets to send a copy to the Pi
sudo iptables -t mangle -A PREROUTING -j TEE --gateway $pi_ip
sudo iptables -t mangle -A POSTROUTING -j TEE --gateway $pi_ip
# TODO: IPv6?

# Save it
sudo sh -c "iptables-save > /etc/iptables/rules.v4"

echo "Done!"
echo 


echo "Setting up PiHole..."
# Set Pi as DNS
sudo pi_ip=$pi_ip /bin/bash -c "echo 'DNS=$pi_ip' >> /etc/systemd/resolved.conf"
sudo old_dns=$old_dna /bin/bash -c "echo 'FallbackDNS=$old_dns' >> /etc/systemd/resolved.conf"
sudo service systemd-resolved restart

echo "Done!"
echo 


echo "All done!"