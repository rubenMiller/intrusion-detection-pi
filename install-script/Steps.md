# Steps

## Pi

- Set up Raspberry

- Create `key` directory

- Generate SSH-Key: `ssh-keygen`

- move to key directory

- Get IP of PI

- Create `configs` directory

- Create smb-share to upload host-configs

```bash
ssh-keygen
sudo mkdir -p /ids/host-configs
sudo mkdir -p /ids/key
sudo chown -R nobody:nogroup /ids/key
sudo chmod -R 777 /ids/key/
cp ~/.ssh/id_rsa.pub /ids/key
sudo chown -R nobody:nogroup /ids/server-configs
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

[key]
   path = /ids/key
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
sudo apt install smbclient iptables iptables-persistent #-y can be added to automate
echo "Done!"
echo .

echo "Generating user 'ids-pi'... "
# Generate user for the PI
# Username of the IDS-PI
pi_user="ids-pi"

useradd $pi_user
usermod -L $pi_user  # Locks the account
echo "Done!"
echo .

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
echo .

echo "Adding pi's ssh-key"
# Get public SSH-Key of Pi
smbclient //"$pi_ip"/"key" -U "$pi_user"%"nG4AghLw" -c "get id_rsa.pub"
cat id_rsa.pub >> /home/$pi_user/.ssh/authorized_keys
rm id_rsa.pub

echo "Done!"
echo .

# Add reading permissions for ids-pi for all relevat files
# TODO: Do so when config is configurated
#for file in "${files[@]}"; do
    #chmod +r $file
#done

# TODO: set Pi as DNS (change when PiHole is ready)
# echo "nameserver $pi_ip" > /etc/resolv.conf

# Send a copy of all packets to the pi for scanning
```

## Further reading

[Linux + how to give only specific user to read the file - Unix & Linux Stack Exchange](https://unix.stackexchange.com/questions/401207/linux-how-to-give-only-specific-user-to-read-the-file)

[resolv.conf - Debian Wiki](https://wiki.debian.org/resolv.conf)
