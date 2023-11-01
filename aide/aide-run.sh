#!/bin/bash
# This script connects to the server and checks whether aide is installed and the integrity of it, if it is installe># Then it pulls the initial database and compares it with the current state of the disk

# fail on error
set -e

# This method needs two arguments: the IP of the Server and the IP of the Host
function runAideForHost() {
        SERVERIP=$1
        HOSTIP=$2

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