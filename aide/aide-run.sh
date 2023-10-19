#!/bin/bash
# This script connects to the server and checks whether aide is installed and the integrity of it, if it is installed.
# Then it pulls the initial database and compares it with the current state of the disk

# fail on error
set -e


export SERVERIP="141.69.97.99"
export HOSTIP=(hostname -I | awk '{print $1}')

# ssh-connection needs to be working at this point, use certificate
ssh aideuser@$SERVERIP

dpkg -V aide

if [ $? -ne 0 ]; then
    echo "The package aide will be (re-)installed."
    apt-get --reinstall install aide
fi


# pull the initial file from the raspery
scp readonlyuser@$HOSTIP:/var/lib/aide/aide.db /var/lib/aide/aide.db

# pull the aide configuration
scp readonlyuser@$HOSTIP:/etc/aide/aide.conf /etc/aide/aide.conf

# compare the current state of the disk with the initial database
aide --config=/etc/aide/aide.conf --check