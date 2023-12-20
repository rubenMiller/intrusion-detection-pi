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

4. Also `<gitRepo>/aide/aide.conf`, `aide-run.sh` and `aide_to_eve.py` (from this repo) should be included in `/ids/aide`

5. `aide.conf` also needs a copy in `/ids/pi-public`: `cp /ids/aide/aide.conf /ids/pi-public/aide.conf && sudo chown nobody:nogroup /ids/pi-public/aide.conf &&sudo chmod 444 /ids/pi-public/aide.conf`

## Setting up aide

The aide-run.sh script looks through the folder /ids/aide/configs and for each contained folder starts the runAideForHost.sh script.
You need to have three files in the same folder aide-run.sh, runAideForHost.sh and runInitialAideForHost.sh and give them permission to be executed.

```bash
chmod +x /ids/aide/aide-run.sh
chmod +x /ids/aide/runAideForHost.sh
chmod +x /ids/aide/runInitialAideForHost.sh
```

When setting up the server, there should be folders created to look like this:

```bash
/ids/host-configs/config-server-hostname
/ids/host-configs/config-another-server
```

These files are on the samba-share, which is open to be written into. The files could be lost and therefore should not be stored there. The aide run script copies the files from there into another folder and accesses it from there. If there is no aide config file given and namend "aide.conf", the default stored in /ids/aide/aide.conf will be used. Store aide config files like this:

```bash
/ids/aide/configs/server-hostname/config-server-hostname
/ids/aide/configs/server-hostname/aide.conf
/ids/aide/configs/another-server/config-another-server
/ids/aide/configs/another-server/aide.conf
```

Now only a cronjob that periodically runs the script needs to be made. This one runs every day at 2 am.

```bash
crontab -e 

# Add this line
0 2 * * * //ids/aide/aide-run.sh
```

## Deprecated: Manually add host

```bash
# Find host-config

host_config=$(grep -rl "IP=$HOSTIP" /ids/host-configs/)
hostname=$(awk -F= -v key="Hostname" '$1==key {print $2}' $host_config)

# push the aide config from the raspberry

# TODO: Wrong File

scp /ids/aide/aide.conf $pi_user@$HOSTIP:~/aide/aide.conf

# scp /ids/aide/aide-init.sh $pi_user@$HOSTIP:~/aide/init.sh #deprecated

ssh $pi_user@$HOSTIP "dpkg -V aide; if [ $? -ne 0 ];
    then echo 'Aide needs to be reinstalled!';
    exit 1;
    fi;
    sudo aide --config=/home/$pi_user/aide/aide.conf --before=\"database_out=file:/home/$pi_user/aide/aide.db.new\" --init
    sudo chown -R $pi_user /home/$pi_user/aide"

mkdir -p /ids/aide/aide-dbs/$hostname
export DATE=$(date +%F_%T)
scp $pi_user@$HOSTIP:/home/$pi_user/aide/aide.db.new /ids/aide/aide-dbs/$hostname/aide-$DATE.db
ln -s /ids/aide/aide-dbs/$hostname/aide-$DATE.db /ids/aide/aide-dbs/$hostname/recent-aide-db
mv $host_config /ids/aide/aide-dbs/$hostname/
```

## Pihole

See [Installation of Pihole](../pihole/steps.md)

## Suricata & Evebox

See [Installation of Suricata & Evebox](../network-ids/Steps.md)
