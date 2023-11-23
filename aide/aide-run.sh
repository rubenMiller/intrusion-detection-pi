#!/bin/bash
# This script runs on the raspberry Pi and starts the check on the server

# fail on error
set -e

# This method needs three arguments:
# 	1. the IP of the Server 
# 	2. the Path to the AIDE-Folder with the DB and server-config (generated in install-script)
# 	3. the User to log in on the server (generated in install-script)
function runAideForHost() {
        SERVERIP=$1
		AIDE_FOLDER=$2
		AIDE_USER=$2


        # push the initial database from the raspberry
        scp $AIDE_FOLDER/recent-aide-db $AIDE_USER@$SERVERIP:/aide/aide.db

        # push the aide config from the raspberry
        scp /etc/aide/aide.conf $AIDE_USER@$SERVERIP:~/aide/aide.conf


		ssh $pi_user@$SERVERIP "dpkg -V aide; if [ $? -ne 0 ];
			then echo 'Aide needs to be reinstalled!';
			exit 1;
			fi;
			sudo aide --config=/home/$pi_user/aide/aide.conf --init;
			sudo aide --config=/home/$pi_user/aide/aide.conf --compare > /aide/output"
		
		# Pull files back to PI
		export DATE=$(date +%F_%T)
		scp $pi_user@$SERVERIP:/aide/aide.db.new $AIDE_FOLDER/aide-$DATE.db
		scp $pi_user@$SERVERIP:/aide/output $AIDE_FOLDER/output-$DATE		
		ln -s ~/aide-dbs/aide-$DATE.db ~/recent-aide-db
	
}

# Path to aide dbs, see Steps-Pi.md
db_dir=/ids/aide/aide-dbs/

# IDS-Pi User on Host. Specified in install-script
pi_user="ids-pi"

# Loop for all directorys (represent hosts to scan) in this directory
for folder in $db_dir*/; do
	echo "$folder"
	# Loop for all files in this directory to find our server-config
	for file in $folder/*; do
		if  [[ -f $file ]] && [[ $file == */config-* ]]; then
			# search for "IP="
			while IFS= read -r line; do
				if [[ $line == IP=* ]]; then
					# Separate the line at "=" and get the IP
					IFS="=" read -ra parts <<< "$line"
					runAideForHost ${parts[1]} ${folder} ${pi_user}
					break
				fi
			done < "$file"
		fi
	done
done