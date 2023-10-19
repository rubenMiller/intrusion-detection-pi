# Steps

## Pi

- Set up Raspberry

- Generate SSH-Key: `ssh-keygen`

- Get IP of PI

- Create user `ids-pi`, which has only permissions for `scp` and `ssh-keyscan`

- Create `configs` directory

```bash
sudo useradd -m -N -s /bin/rbash ids-pi
echo "ids-pi:nG4AghLw" | sudo chpasswd
echo "exit" > /home/ids-pi/.bashrc
sudo -u ids-pi mkdir /home/ids-pi/configs
sudo nano /etc/ssh/sshd_config
# after below:
sudo service ssh restart
```

```text
Match User ids-pi
       AllowTcpForwarding no
       PasswordAuthentication yes
       PermitRootLogin no
       X11Forwarding no
       PermitTunnel no
       AllowAgentForwarding no
       ForceCommand internal-sftp
       ChrootDirectory /home/ids-pi
```

Comments to the above:

Using `/bin/rbash` as the shell for the `ids-pi` user ensures that this user does not receive a regular interactive shell.

- `-m` create home

- `-N` no user group

- `-s` shell to use

Using `"exit"` in the `.bashrc`, so if someone manages to log in as this user, he gets immediately kicked out.

A `sshd_config`, which should only allow `scp` and `ssh-keyscan` for the user `ids-pi`

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

# Path on the Raspberry Pi to save the files
pi_file_dir="~/configs/$(hostname -f)"

# Generate config-file
config_file=".temp-config"
echo "Hostname=$(hostname -f)" > $config_file
echo "IP=$(ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+')" >> $config_file # IP Address, used to connect to the Internet
    # From: https://stackoverflow.com/questions/21336126/linux-bash-script-to-extract-ip-address

# Add list of files
for file in "${files[@]}"; do
    echo "File=$file" >> $config_file
done

sudo apt update
sudo apt install sshpass 

# Copy config to Pi
sshpass -p "nG4AghLw" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $config_file $pi_user@$pi_ip:$pi_file_dir || true

# Remove temp file
rm ".temp-config"

# Get public SSH-Key of Pi
ssh-keyscan $pi_ip >> /home/$pi_user/.ssh/known_hosts

# Füge Leserechte für den Raspberry Pi zu den Dateien hinzu
for file in "${files[@]}"; do
    chmod +r $file
done

# Setze Raspberry Pi als DNS und Gateway
echo "nameserver $pi_ip" > /etc/resolv.conf
echo "GATEWAY=$pi_ip" >> /etc/sysconfig/network
```
