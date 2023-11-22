# Installing anything on the PI

Since there are many Steps to perform on the PI spread around many files, here is a quick summary. This can be outdated, so check out other Step-Files to be sure.

## Requirements

Software we need in order to install anything else. Suricate is **not** included

```bash
sudo apt install samba samba-common-bin aide iptables wget gnupg apt-transport-https
```

## SAMBA and included Files

1. ```bash
   ssh-keygen
   sudo mkdir -p /ids/host-configs
   sudo mkdir -p /ids/pi-public
   sudo chown -R nobody:nogroup /ids/pi-public
   sudo chmod -R 777 /ids/pi-public
   cp ~/.ssh/id_rsa.pub /ids/pi-public
   sudo chown -R nobody:nogroup /ids/host-configs
   sudo chmod -R 777 /ids/host-configs/
   ```

2. Edit: `sudo nano /etc/samba/smb.conf`
   
   ```bash
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

3. ```bash
   sudo smbpasswd -a ids-pi # 'nG4AghLw' is password. Errors can be ignored
   sudo service smbd restart
   ```

4. Also `/etc/aide/aide.conf` and `aide-init.sh` (from this repo) should be included in `/ids/pi-public`

## TODO: Manually adding Host on PI

If a new Host wants to be part of AIDE, it will be configured in the `install-script.sh` but it needs to be added here too. We will change this later, but at the Moment, it needs do be manually done

```bash
pi_user="ids-pi"
HOSTIP="192..."

# Find host-config
host_config=$(grep -rl "IP=$HOSTIP" /ids/host-configs/)
hostname=$(awk -F= -v key="Hostname" '$1==key {print $2}' $host_config)

# push the aide config from the raspberry
scp /etc/aide/aide.conf $pi_user@$HOSTIP:~/aide/aide.conf
scp /ids/aide/aide-init.sh $pi_user@$HOSTIP:~/aide/init.sh

ssh $pi_user@$HOSTIP"dpkg -V aide; if [ $? -ne 0 ];
    then echo 'Aide needs to be reinstalled!';
    exit 1;
    fi;
    sudo aide --config=/home/$pi_user/aide/aide.conf --init"

mkdir -p /ids/aide/aide-dbs/$hostname
export DATE=$(date +%F_%T)
scp $pi_user@$SERVERIP:/var/lib/aide/aide.db.new /ids/aide/aide-dbs/$hostname/aide-$DATE.db
ln -s /ids/aide/aide-dbs/$hostname/aide-$DATE.db /ids/aide/aide-dbs/$hostname/recent-aide-db
mv $host_config /ids/aide/aide-dbs/$hostname/
```

## Pihole

See [Installation of Pihole](../pihole/steps.md)

## Suricata & Evebox

See [Installation of Suricata & Evebox](../network-ids/Steps.md)
