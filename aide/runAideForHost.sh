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

# Search and replace <<pi_user>> by actual user
if [ ! -f "$AIDE_FOLDER/aide.conf" ]; then
    echo "The file $AIDE_FOLDER/aide.conf does not exist, copying default from /ids/aide/aide.conf."
    cp /ids/aide/aide.conf $AIDE_FOLDER/
fi
sed -i "s/<<pi_user>>/$AIDE_USER/g" $AIDE_FOLDER/aide.conf

if [ ! -f "$AIDE_FOLDER/recent-aide-db" ]; then
    echo "The file $AIDE_FOLDER/recent-aide-db does not exists, therefore aide needs to be initialised, starting respective script."
    ./runInitialAideForHost.sh ${SERVERIP} ${AIDE_FOLDER} ${AIDE_USER}
    exit
fi

# push the initial or last database from the raspberry
scp $AIDE_FOLDER/recent-aide-db $AIDE_USER@$SERVERIP:/home/$pi_user/aide/aide.db

# push the aide config from the raspberry
scp $AIDE_FOLDER/aide.conf $AIDE_USER@$SERVERIP:~/aide/aide.conf


ssh $pi_user@$SERVERIP "dpkg -V aide; if [ $? -ne 0 ];
    then echo 'Aide needs to be reinstalled!';
    exit 1;
    fi;
    sudo aide --config=/home/$pi_user/aide/aide.conf --init;
    sudo aide --config=/home/$pi_user/aide/aide.conf --compare > /home/$pi_user/aide/output.json
    sudo chown -R $pi_user /home/$pi_user/aide"

# Pull files back to PI
export DATE=$(date +%F_%T)
scp $pi_user@$SERVERIP:/home/$pi_user/aide/aide.db.new $AIDE_FOLDER/aide-$DATE.db
scp $pi_user@$SERVERIP:/home/$pi_user/aide/output.json $AIDE_FOLDER/output-$DATE.json
rm -f $AIDE_FOLDER/recent-aide-db
ln -s $AIDE_FOLDER/aide-$DATE.db $AIDE_FOLDER/recent-aide-db
python /ids/aide/aide_to_eve.py $AIDE_FOLDER/output-$DATE.json $AIDE_FOLDER/output-eve-$DATE.json $SERVERIP
cat $AIDE_FOLDER/output-eve-$DATE.json >> /ids/aide/output-eve.json