#!/bin/bash
# This script runs on the raspberry Pi and starts the script for each server

# Does not fail on error

# Logging
(
export DATE=$(date +%F_%T)
echo "Aide-run at $DATE:"

# Path to aide dbs, see Steps-Pi.md
db_dir=/ids/aide/configs
samba_dir=/ids/host-configs

# IDS-Pi User on Host. Specified in install-script
pi_user="ids-pi"

echo -e "Dirs:\n\tDB-Dir: $db_dir\n\tSamba-Dir: $samba_dir"
echo -e "Pi-User: $pi_user"

# Iterate through files in /ids/host-configs
echo "Checking for new Hosts..."
for config_file in "$samba_dir"/*; do
	if [ -f "$config_file" ]; then
		# Extract hostname from the config file name
		hostname=$(basename "$config_file" | sed 's/config-//')

		# Check if the corresponding folder exists in /ids/aide/aide-dbs
		aide_folder="$db_dir/$hostname"
		echo "Current AIDE-Folder: $aide_folder"
		if [ ! -d "$aide_folder" ]; then
			# If the folder doesn't exist, create it 
			echo "Adding new configurations for Host: $hostname."
			mkdir -p "$aide_folder"
			mv "$config_file" "$aide_folder/"
		fi
	fi
done

echo "done"
echo


# Loop through the directories in the given path
echo "Running AIDE for all Hosts..."
for server_folder in "$db_dir"/*/; do
	hostname=$(basename "$server_folder")

	host_config_file="$db_dir/$hostname/config-$hostname"
	aide_folder="$db_dir/$hostname/"
	echo -e "Currently:\n\tHostname: $hostname\n\tHost-Config-File: $host_config_file\n\tAIDE-Folder: $aide_folder"

	if [ -f "$host_config_file" ]; then
		echo "Reading config for server: $db_dir$hostname"

		while IFS= read -r line; do
			if [[ $line == IP=* ]]; then
				# Separate the line at "=" and get the IP
				IFS="=" read -ra parts <<< "$line"

				echo "Starting script for Host: ${parts[1]}."

				# Run the runAideForHost.sh script
				echo "/ids/aide/runAideForHost.sh ${parts[1]} ${aide_folder} ${pi_user}"
				/ids/aide/runAideForHost.sh ${parts[1]} ${aide_folder} ${pi_user}

				echo "Script for Host: ${parts[1]} finished."
				echo 
				break
			fi
		done < "$host_config_file"
	else
		echo "Configuration file $host_config_file not found."
	fi
done
echo "done"

echo -e "Aide-run complete\n\n"

) 2>&1 | tee -a /ids/aide/aide-run.log