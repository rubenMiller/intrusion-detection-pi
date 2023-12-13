#!/bin/bash
# This script runs on the raspberry Pi and starts the script for each server

# Does not fail on error

# Path to aide dbs, see Steps-Pi.md
db_dir=/ids/aide/configs/
samba_dir="/ids/host-configs"
#db_dir="./test/c"
#samba_dir="./test/b"

# Iterate through files in /ids/host-configs
for config_file in "$samba_dir"/*; do
    # Extract hostname from the config file name
    hostname=$(basename "$config_file" | sed 's/config-//')

    # Check if the corresponding folder exists in /ids/aide/aide-dbs
    aide_folder="$db_dir/$hostname"
    if [ ! -d "$aide_folder" ]; then
        # If the folder doesn't exist, create it 
		echo "Adding new configurations for Host: $hostname."
        mkdir -p "$aide_folder"
    	mv "$config_file" "$aide_folder/"
    fi
done

# IDS-Pi User on Host. Specified in install-script
pi_user="ids-pi"

# Loop through the directories in the given path
for server_folder in "$db_dir"/*/; do
	hostname=$(basename "$server_folder")

	host_config_file="$db_dir/$hostname/config-$hostname"
	aide_folder="$db_dir/$hostname/"

	if [ -f "$host_config_file" ]; then
		echo "Reading config for server: $db_dir$hostname"

		while IFS= read -r line; do
			if [[ $line == IP=* ]]; then
				# Separate the line at "=" and get the IP
				IFS="=" read -ra parts <<< "$line"

				echo -e "\nStarting script for Host: ${parts[1]}."

				# Run the runAideForHost.sh script
				./runAideForHost.sh ${parts[1]} ${aide_folder} ${pi_user} #TODO: calling scripts with ./ requires to set the Working Directory: `cd "$(dirname "$0")"`; Needs testing

				echo "Script for Host: ${parts[1]} finished."
				break
			fi
		done < "$host_config_file"
	else
		echo "Configuration file $host_config_file not found."
	fi
done

