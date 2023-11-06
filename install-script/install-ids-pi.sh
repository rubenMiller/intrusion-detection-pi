#!/bin/bash
set -x # Debugging: Print command before printing
# Exit on error
# set -e

# Read ip of IDS-Pi
read -p "Please enter the IP-Address of the IDS-PI: " pi_ip

echo "Installing requirements... "
# Requirements: smbclient, 
sudo apt update
sudo apt install smbclient iptables iptables-persistent #-y can be added to automate
echo "Done!"
echo 

echo "Generating user 'ids-pi'... "
# Generate user for the PI
# Username of the IDS-PI
pi_user="ids-pi"

sudo useradd $pi_user
sudo usermod -L $pi_user  # Locks the account
echo "Done!"
echo 

echo "Generating config for pi..."
# List of files to add read permissions for the Pi
declare -a files=("datei1" "datei2" "datei3")

# Generate config-file
config_file="config-$(hostname -f)"
echo "Hostname=$(hostname -f)" > $config_file
echo "IP=$(ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+')" >> $config_file # IP Address, used to connect to the Internet
    # From: https://stackoverflow.com/questions/21336126/linux-bash-script-to-extract-ip-address

# Add list of files
for file in "${files[@]}"; do
    echo "File=$file" >> $config_file
done

# Copy config to Pi using smbclient (see requirements)
smbclient //"$pi_ip"/"configs" -U "$pi_user"%"nG4AghLw" -c "put $config_file"

# Remove temp file
rm $config_file

echo "Done!"
echo 

echo "Adding pi's ssh-key..."
# Get public SSH-Key of Pi
smbclient //"$pi_ip"/"key" -U "$pi_user"%"nG4AghLw" -c "get id_rsa.pub"
sudo mkdir -p /home/$pi_user/.ssh/
sudo sh -c "cat id_rsa.pub >> /home/$pi_user/.ssh/authorized_keys"
rm id_rsa.pub

echo "Done!"
echo 

echo "Setting up network IDS..."
# Configure IPTables to clone all incoming and outgoing pakets to send a copy to the Pi
sudo iptables -t mangle -A PREROUTING -j TEE --gateway $pi_ip
sudo iptables -t mangle -A POSTROUTING -j TEE --gateway $pi_ip

# Save it
sudo sh -c "iptables-save > /etc/iptables/rules.v4"

echo "Done!"
echo 
# Add reading permissions for ids-pi for all relevat files
# TODO: Do so when config is configurated
#for file in "${files[@]}"; do
    #chmod +r $file
#done

# TODO: set Pi as DNS (change when PiHole is ready)
# echo "nameserver $pi_ip" > /etc/resolv.conf

# Send a copy of all packets to the pi for scanning
echo "All done!"