#!/bin/bash

# IBM Confidential
# PID 5900B4I
# Copyright (c) IBM Corp. 2023,2024,2025

# Get the directory where the script is located
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
version="2.2.5"
swidtag=ibm.com_IBM_Quantum_Safe_Explorer-"$version".swidtag
swidtag_file="$script_dir/swidtag/$swidtag"

# Define the license file path
license_file="$script_dir/la_home/LA_en"
license_config_file="$script_dir/LicenseAcceptance.config"
config_file="$script_dir/configuration.prop"
user_home_li_dir="$HOME/qs-explorer/license"
swidtag_dir="$HOME/qs-explorer/swidtag"
status_file="$user_home_li_dir/status.dat"
license_accepted="false"

perform_la_acceptance(){

	user_home_li_dir="$HOME/qs-explorer/license"
	local passed_args="$1"
	status=9
	# Check if the target directory exists, and if not, create it
	if [ ! -d "$user_home_li_dir" ]; then
		mkdir -p "$user_home_li_dir"
		chmod -R 777 "$user_home_li_dir"
	fi

	# Source directory
	source_directory="$script_dir/la_home"

	for file in "$source_directory"/*; do
		# Extract the filename without extension
		filename=$(basename "$file")

		if [[ "$filename" != LA_* ]]; then
			continue
		fi

		# Determine the language code (e.g., LA_en or LA_fr)
		language_code=$(echo "$filename" | sed -E 's/LA_([a-z]+).*/\1/')

		# Map language codes to corresponding language names
		case "$language_code" in
			en) language_name="English";;
			fr) language_name="French";;
			cs) language_name="Czech";;
			de) language_name="German";;
			el) language_name="Greek";;
			es) language_name="Spanish";;
			in) language_name="Indonesian";;
			it) language_name="Italian";;
			ja) language_name="Japanese";;
			ko) language_name="Korean";;
			lt) language_name="Lithuanian";;
			pl) language_name="Polish";;
			pt) language_name="Portuguese";;
			ru) language_name="Russian";;
			sl) language_name="Slovenian";;
			tr) language_name="Turkish";;
			zh) language_name="Chinese";;
		esac

		# Create the new filename
		new_filename="$language_name.txt"

		# Copy the file to the destination directory with the new name
		cp "$file" "$user_home_li_dir/$new_filename"

	done
	license_accepted="true"
}

check_for_license(){

		if [ -f "$license_config_file" ]; then
			# Read properties from the config file
			source "$license_config_file"
			set accept_license="false"
			# Convert accept_license value to lowercase for comparison
			accept_license=$(echo "$RSP_LICENSE_ACCEPTED" | tr '[:upper:]' '[:lower:]')

			# Check the value of accept_license
			if [ "$accept_license" = "true" ]; then
				echo "License accepted. Performing required action..."
				echo ""
				perform_la_acceptance "${array[@]}"
			elif [ "$accept_license" = "false" ]; then

				if [ -f "$license_file" ]; then
					# Read license text from file
					license_text=$(cat "$license_file")
					# Display license text to the user
					echo "";
					echo "$license_text"

					# Prompt the user to accept the license
					read -p "Do you accept the license? (yes/no): " response

					# Convert the response to lowercase for easier comparison
					response_lc=$(echo "$response" | tr '[:upper:]' '[:lower:]')

					status=3

					# Check user's response
					if [ "$response_lc" = "yes" ]; then
						echo "License accepted. Performing required action..."
						perform_la_acceptance

					elif [ "$response_lc" = "no" ]; then
						echo "License not accepted. Exiting..."
						status=3
						# You can add further actions if needed
					else
						status=3
						echo "Invalid response. Please type 'yes' or 'no'."
					fi
				else
					status=1
					echo "License file not found in the script's directory."
				fi
			else
				echo "Invalid value for accept_license in the config file."
			fi

		else
			echo "License Config file not found."
		fi
		# Create the content for the status.dat file
		timestamp=$(date +"#%a %b %d %T %Z %Y")
		content="$timestamp\nStatus=$status"
		if [ ! -d "$user_home_li_dir" ]; then
			mkdir -p "$user_home_li_dir"
			chmod -R 777 "$user_home_li_dir"
		fi

		if [ ! -e "$status_file" ]; then
			echo "Thank You ..."
			echo > "$status_file"
		fi
		# Write the content to the status.dat file
		echo -e "$content" > "$status_file"

}

get_heap_size_mb() {
    # Get total memory in bytes using sysctl
    if [[ "$OSTYPE" == "darwin"* ]]; then
        total_memory_bytes=$(sysctl -n hw.memsize)
        # Convert memory to MB
    	total_memory_mb=$((total_memory_bytes / 1024 / 1024))
    elif [[ "$OSTYPE" == "cygwin"* ]]; then
        total_memory_bytes=$(wmic computersystem get TotalPhysicalMemory | grep -Eo '[0-9]+')
        total_memory_mb=$((total_memory_bytes / 1024 / 1024))
	elif [[ "$OSTYPE" == "win"* || "$OSTYPE" == "msys"* ]]; then
		total_memory_bytes=16777216000 
		if command -v wmic >/dev/null 2>&1; then
			total_memory_bytes=$(wmic computersystem get TotalPhysicalMemory | grep -Eo '[0-9]+')
		else
			total_memory_bytes=$(powershell -command "(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory")
		fi
		total_memory_mb=$((total_memory_bytes / 1024 / 1024))
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        total_memory_bytes=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        total_memory_mb=$((total_memory_bytes / 1024))
    else
        total_memory_bytes=34359738368
        total_memory_mb=$((total_memory_bytes / 1024 / 1024))
    fi

    # Calculate heap size as a percentage of total memory, e.g., 75%
    heap_size_mb=$((total_memory_mb * 75 / 100))

    # Print total memory and heap size
    echo "Total Memory: ${total_memory_mb} MB"
    echo "Calculated Heap Size: ${heap_size_mb} MB"

    # Return the calculated heap size
    echo $heap_size_mb
}

if [ -e "$swidtag_file" ]; then
	if [ -e "$swidtag_dir/$swidtag" ]; then
		echo "Swidtag file already present."
	else
		cp -r "$script_dir/swidtag/" "$HOME/qs-explorer"
	fi
	echo "before settings file "
	if [ -f "$config_file" ]; then
		source "$config_file"
			vulConfigPath=$(grep '^VULNERABILITY_CONFIG_PATH=' "$config_file" | cut -d'=' -f2-)
			echo $vulConfigPath
	fi
	if [ -f "$status_file" ]; then
		source $status_file
		# Store the arguments in a variable

		if [ "$Status" = "9" ]; then
			echo "License Agreement have been already completed."
            heap_size=$(get_heap_size_mb | tail -n 1)
            echo "Using Heap Size: ${heap_size} MB"
			if [ -z "$vulConfigPath" ]; then
				java -Xmx${heap_size}m -Xms2g -Xmn1g -Xss2m -XX:+UseG1GC -Dfile.encoding=UTF-8 -cp "lib/*" com.ibm.quantumsafe.lang.driver.CryptoCli "$@"
			else
				java -Xmx${heap_size}m -Xms2g -Xmn1g -Xss2m -XX:+UseG1GC -Dfile.encoding=UTF-8 -cp "lib/*" com.ibm.quantumsafe.lang.driver.CryptoCli -vp "$vulConfigPath" "$@"
			fi
		else
			check_for_license
		fi
	else
		echo "License Agreement have not been accepted.Please accept the license agreement to continue."
		check_for_license
	fi
	
	if [ "$license_accepted" = "true" ]; then
                heap_size=$(get_heap_size_mb | tail -n 1)
                echo "Using Heap Size: ${heap_size} MB"
			if [ -z "$vulConfigPath" ]; then
				java -Xmx${heap_size}m -Xms2g -Xmn1g -Xss2m -XX:+UseG1GC -Dfile.encoding=UTF-8 -cp "lib/*" com.ibm.quantumsafe.lang.driver.CryptoCli "$@"
			else
				java -Xmx${heap_size}m -Xms2g -Xmn1g -Xss2m -XX:+UseG1GC -Dfile.encoding=UTF-8 -cp "lib/*" com.ibm.quantumsafe.lang.driver.CryptoCli -vp "$vulConfigPath" "$@"
			fi
	fi
else
  echo "License Agreement swidtag file not found.Please update the project with latest data files."
fi
