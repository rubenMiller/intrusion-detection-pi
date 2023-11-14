#!/bin/bash
# This script runs on the raspberry Pi and starts the check on the server


# fail on error
set -e

# This method needs two arguments: the IP of the Server and the IP of the Host
function runAideForHost() {
        SERVERIP=$1
        #TODO this doe snot work that way, change
        # ssh-connection needs to be working at this point, use certificate
        # ssh aideuser@$SERVERIP


        # push the initial database from the raspberry
        scp ~/recent-aide-db aideuser@$SERVERIP:/aide/aide.db

        # push the aide config from the raspberry
        scp /etc/aide/aide.conf aideuser@$SERVERIP:~/aide/aide.conf

    ssh $pi_user@$SERVERIP "dpkg -V aide; if [ $? -ne 0 ];
        then echo 'Aide needs to be reinstalled!';
        exit 1;
        fi;
        sudo aide --config=/home/$pi_user/aide/aide.conf --init"
}

# Path to host configs
config_dir="/ids/host-configs"

# Ip of host
hostip="$(hostname -I | awk '{print $1}')"

# Loop for all configs in this directory
for config_file in "$config_dir"/*; do
    if [ -f "$config_file" ]; then
        # search for "IP="
        while IFS= read -r line; do
            if [[ $line == IP=* ]]; then
                # Separate the line at "=" and get the IP
                IFS="=" read -ra parts <<< "$line"
                runAideForHost ${parts[1]} ${hostip}
                break
            fi
        done < "$config_file"
    fi
done