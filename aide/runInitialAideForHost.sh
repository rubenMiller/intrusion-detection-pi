#!/bin/bash
# This script runs on the raspberry Pi and starts the check on the given server

# fail on error
set -e

# This needs three arguments:
# 	1. the IP of the Server 
# 	2. the Path to the AIDE-Folder with the DB and server-config (generated in install-script)
# 	3. the User to log in on the server (generated in install-script)

SERVERIP=$1
AIDE_FOLDER=$2
AIDE_USER=$3


# push the aide config from the raspberry
scp $AIDE_FOLDER/aide.conf $AIDE_USER@$SERVERIP:~/aide/aide.conf


ssh $pi_user@$SERVERIP "dpkg -V aide; if [ $? -ne 0 ];
    then echo 'Aide needs to be reinstalled!';
    exit 1;
    fi;
    sudo aide --config=/home/$pi_user/aide/aide.conf --init;
    sudo chown -R $pi_user /home/$pi_user/aide"

# Pull files back to PI
export DATE=$(date +%F_%T)
scp $pi_user@$SERVERIP:/home/$pi_user/aide/aide.db.new $AIDE_FOLDER/aide-$DATE.db
ln -s $AIDE_FOLDER/aide-$DATE.db $AIDE_FOLDER/recent-aide-db
python /ids/aide/aide_to_eve.py $AIDE_FOLDER/output-$DATE.json $AIDE_FOLDER/output-eve-$DATE.json $SERVERIP
cat $AIDE_FOLDER/output-eve-$DATE.json >> /ids/aide/output-eve.json