# Steps

## Pi

- Set up Raspberry

- Create `pi-public` directory

- Generate SSH-Key: `ssh-keygen`

- move to `pi-public` directory

- move aide-confs (`/etc/aide/aide.conf` and `~/aide-init.sh`) to `pi-public`

- Get IP of PI

- Create `configs` directory

- Create smb-share to upload host-configs

```bash
ssh-keygen
sudo mkdir -p /ids/host-configs
sudo mkdir -p /ids/pi-public
sudo chown -R nobody:nogroup /ids/pi-public
sudo chmod -R 777 /ids/pi-public
cp ~/.ssh/id_rsa.pub /ids/pi-public
sudo chown -R nobody:nogroup /ids/host-configs
sudo chmod -R 777 /ids/host-configs/
sudo apt-get install samba samba-common-bin
sudo nano /etc/samba/smb.conf
# after below:
sudo smbpasswd -a ids-pi # 'nG4AghLw' is password. Errors can be ignored
sudo service smbd restart
```

```text
[configs]
   path = /ids/host-configs
   writeable = yes
   browsable = no
   guest ok = yes
   guest account = ids-pi

[pi-public]
   path = /ids/pi-public
   writeable = no
   browsable = yes
   guest ok = yes
   guest account = ids-pi
```

Comments to the above:

A smb-share to upload the host-configs

## Server

- Set up Server

### Script

- Read IP of PI

- Add new User for IDS-PI
  
  - Don't need home?
  
  - Needs Read-Permissions for all necessary files

- Get SSH-key from IDS-Pi so it can log in under it's IDS-Pi user

- Tell Pi IP, Hostname and necessary files of Server

- Set DNS to Address of PI

- Set gateway to IP of Pi

```bash
#!/bin/bash
set -x # Debugging: Print command before printing
# Exit on error
set -e

# Read ip of IDS-Pi
read -p "Please enter the IP-Address of the IDS-PI: " pi_ip

echo "Installing requirements... "
# Requirements: smbclient, 
sudo apt update
sudo apt install smbclient iptables iptables-persistent sudo acl systemd-resolved resolvconf #-y can be added to automate
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

sudo -u $pi_user mkdir /aide/
sudo setfacl -m $pi_user:r-x /aide/*
echo "Done!"
echo 

echo "Generating config for pi..."

# Generate config-file
config_file="config-$(hostname -f)"
echo "Hostname=$(hostname -f)" > $config_file
echo "IP=$(ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+')" >> $config_file # IP Address, used to connect to the Internet
    # From: https://stackoverflow.com/questions/21336126/linux-bash-script-to-extract-ip-address
echo "Fingerprint=$(ssh-keyscan -t ed25519 127.0.0.1 | cut -f 2,3 -d ' ')" >> $config_file

# Copy config to Pi using smbclient (see requirements)
smbclient //"$pi_ip"/"configs" -U "$pi_user"%"nG4AghLw" -c "put $config_file"

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
smbclient //"$pi_ip"/"pi-public" -U "$pi_user"%"nG4AghLw" -c "get aide-init.sh"
sudo -u $pi_user mkdir -p /home/$pi_user/aide/
mv aide.conf /home/$pi_user/aide/aide.conf
mv aide-init.sh /home/$pi_user/aide/init.sh
sudo chown $pi_user /home/$pi_user/aide/*

sudo -u $pi_user sudo aide --config=/home/$pi_user/aide/aide.conf --init
# TODO: Datenbank muss jetzt auf den Server. Wie? (Darf die Alte nicht überschreiben, da Sicherheitsrisiko)
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
old_dns="$(resolvectl --no-pager |grep Server |cut -d " " -f 6)"
sudo pi_ip=$pi_ip /bin/bash -c "echo 'nameserver $pi_ip' > /etc/resolvconf/resolv.conf.d/head"
sudo old_dns=$old_dna /bin/bash -c "echo 'nameserver $old_dns' > /etc/resolvconf/resolv.conf.d/head"

echo "Done!"
echo 


echo "All done!"
```

Hint: If there are errors with this script, use `dos2unix`

## Further reading

[Linux + how to give only specific user to read the file - Unix & Linux Stack Exchange](https://unix.stackexchange.com/questions/401207/linux-how-to-give-only-specific-user-to-read-the-file)

[resolv.conf - Debian Wiki](https://wiki.debian.org/resolv.conf)
