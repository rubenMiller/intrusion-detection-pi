#!/bin/bash
# This script runs on the raspberry Pi and starts the check on the server


# fail on error
set -e

# This method needs two arguments: the IP of the Server and the IP of the Host
function runAideForHost() {
        SERVERIP=$1
        HOSTIP=$2
        #TODO this doe snot work that way, change
        # ssh-connection needs to be working at this point, use certificate
        # ssh aideuser@$SERVERIP


        # push the initial database from the raspberry
        scp aideuser@$SERVERIP:/var/lib/aide/aide.db /var/lib/aide/aide.db

        # push the aide config from the raspberry
        scp aideuser@$SERVERIP:/etc/aide/aide.conf /etc/aide/aide.conf

        ssh aideuser@$SERVERIP "dpkg -V aide; if [ $? -ne 0 ]; 
            then echo 'The package aide will be (re-)installed.'; 
            apt-get --reinstall install aide; 
            fi; 
            aide --config=/etc/aide/aide.conf --check"
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