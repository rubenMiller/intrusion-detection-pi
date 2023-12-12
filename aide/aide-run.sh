#!/bin/bash
# This script runs on the raspberry Pi and starts the script for each server

# Does not fail on error

# Path to aide dbs, see Steps-Pi.md
db_dir=/ids/aide/configs/


# IDS-Pi User on Host. Specified in install-script
pi_user="ids-pi"

# Loop through the directories in the given path
for server_folder in "$db_dir"/*/; do
	server_name=$(basename "$server_folder")

	host_config_file="$db_dir/$server_name/config-$server_name"
	aide_folder="$db_dir/$server_name/"

	if [ -f "$host_config_file" ]; then
		echo "Reading config for server: $db_dir$server_name"

		while IFS= read -r line; do
			if [[ $line == IP=* ]]; then
				# Separate the line at "=" and get the IP
				IFS="=" read -ra parts <<< "$line"

				echo -e "\nStarting script for Host: ${parts[1]}."

				# Run the runAideForHost.sh script
				chmod +x ./runAideForHost.sh 
				./runAideForHost.sh ${parts[1]} ${aide_folder} ${pi_user}

				echo "Script for Host: ${parts[1]} finished."
				break
			fi
		done < "$host_config_file"
	else
		echo "Configuration file $host_config_file not found."
	fi
done

