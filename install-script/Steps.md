# Steps

## Pi

- Set up Raspberry

- Generate SSH-Key: `ssh-keygen`

- Get IP of PI

- Create `configs` directory

- Create smb-share to upload host-configs

```bash
sudo mkdir -p /ids/host-configs
sudo chown -R nobody:nogroup /ids/server-configs
sudo chmod -R 777 /ids/host-configs/
sudo apt-get install samba samba-common-bin
# after below:
sudo smbpasswd -a ids-pi # 'nG4AghLw' is password. Errors can be ignored
sudo nano /etc/samba/smb.conf
```

```text
[configs]
   path = /ids/host-configs
   writeable = yes
   browsable = no
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

# Generate user for the PI
# Username of the IDS-PI
pi_user="ids-pi"

useradd $pi_user
usermod -L $pi_user  # Locks the account

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

# Install smbclient
sudo apt update
sudo apt install smbclient -y

# Copy config to Pi
smbclient //"$pi_ip"/"configs" -U "$pi_user"%"nG4AghLw" -c "put $config_file"

# Remove temp file
rm $config_file

# Get public SSH-Key of Pi
ssh-keyscan $pi_ip >> /home/$pi_user/.ssh/known_hosts

# Add reading permissions for ids-pi for all relevat files
for file in "${files[@]}"; do
    chmod +r $file
done

# set Pi as DNS and Gateway
echo "nameserver $pi_ip" > /etc/resolv.conf
echo "GATEWAY=$pi_ip" >> /etc/sysconfig/network
```

## Versuch 2: SMB Share statt eines Nutzers

Pi:

```bash
sudo apt-get install samba samba-common-bin
sudo nano /etc/samba/smb.conf
#nach Config
sudo service smbd restart
```

```ini
[configs-share]
   path = /home/ids-pi/configs
   read only = yes
   write list = ids-pi
```
## Further reading
[Linux + how to give only specific user to read the file - Unix & Linux Stack Exchange](https://unix.stackexchange.com/questions/401207/linux-how-to-give-only-specific-user-to-read-the-file)
