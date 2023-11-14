# Steps to set up aide

## On server

```bash

pi_user="pi-user"

useradd -m -s /bin/bash -g users -G sudo -p $(openssl passwd -1 password) $pi_user
su $pi_user
sudo mkdir /aide/
sudo chown $pi_user /aide/

sudo apt install acl
sudo setfacl -m $pi_user:r-x /aide/*
```

Add the following lines with

```bash
sudo visudo
```

```bash
pi-user ALL = NOPASSWD: /usr/bin/aide
pi-user ALL = NOPASSWD: /usr/bin/dpkg -V
```

## On pi

```bash
pi_user="pi-user"
SERVERIP="192..."

ssh-copy-id -i ~/.ssh/id_rsa.pub $pi_user@$SERVERIP

# push the aide config from the raspberry
scp /etc/aide/aide.conf $pi_user@$SERVERIP:~/aide/aide.conf
scp ~/aide-init.sh $pi_user@$SERVERIP:~/aide/init.sh

ssh $pi_user@$SERVERIP "dpkg -V aide; if [ $? -ne 0 ];
    then echo 'Aide needs to be reinstalled!';
    exit 1;
    fi;
    sudo aide --config=/home/$pi_user/aide/aide.conf --init"

mkdir ~/aide-dbs/
export DATE=$(date +%F_%T)
scp $pi_user@$SERVERIP:/aide/aide.db.new ~/aide-dbs/aide-$DATE.db
ln -s ~/aide-dbs/aide-$DATE.db ~/recent-aide-db
```
