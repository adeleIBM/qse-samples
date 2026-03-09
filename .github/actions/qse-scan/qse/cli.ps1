# IBM Confidential
# PID 5900B4I
# Copyright (c) IBM Corp. 2023,2024,2025


# Get the directory where the script is located
$script_dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$version = "2.2.4"
$swidtag = "ibm.com_IBM_Quantum_Safe_Explorer-$version.swidtag"
$swidtag_file = Join-Path $script_dir "swidtag\$swidtag"

# Define the license file path
$license_file = Join-Path $script_dir "la_home\LA_en"
$license_config_file = Join-Path $script_dir "LicenseAcceptance.config"
$config_file="$script_dir/configuration.prop"
$user_home_li_dir = "$HOME\qs-explorer\license"
$swidtag_dir = "$HOME\qs-explorer\swidtag"
$status_file = Join-Path $user_home_li_dir "status.dat"
$global:license_accepted = "false"

function Perform-LA-Acceptance {
    $user_home_li_dir = "$HOME\qs-explorer\license"
    # Check if the target directory exists, and if not, create it
    if (-not (Test-Path $user_home_li_dir)) {
        New-Item -ItemType Directory -Path $user_home_li_dir
        icacls $user_home_li_dir /grant "Everyone:F"
	# Grant full access (all rights to all users, similar to chmod 777)
        # This might be stricter in actual use cases.
    }
    # Source directory
    $source_directory = Join-Path $script_dir "la_home"

    # Copy language files
    Get-ChildItem -Path $source_directory | ForEach-Object {
        # Extract the filename
        $filename = $_.Name

        if ($filename -notlike "LA_*") {
            return
        }

        # Determine the language code
        $language_code = $filename -replace 'LA_([a-z]+).*', '$1'

        # Map language codes to corresponding language names
        $language_map = @{
            'en' = 'English'
            'fr' = 'French'
            'cs' = 'Czech'
            'de' = 'German'
            'el' = 'Greek'
            'es' = 'Spanish'
            'in' = 'Indonesian'
            'it' = 'Italian'
            'ja' = 'Japanese'
            'ko' = 'Korean'
            'lt' = 'Lithuanian'
            'pl' = 'Polish'
            'pt' = 'Portuguese'
            'ru' = 'Russian'
            'sl' = 'Slovenian'
            'tr' = 'Turkish'
            'zh' = 'Chinese'
        }
        $language_name = $language_map[$language_code]

        # Create the new filename
        $new_filename = "$language_name.txt"

        # Copy the file to the destination directory with the new name
        Copy-Item -Path $_.FullName -Destination (Join-Path $user_home_li_dir $new_filename)
    }
    $global:status = 9
    $global:license_accepted = "true"
}

function Check-For-License {
    if (Test-Path $license_config_file) {
        # Read properties from the config file
        $config = Get-Content $license_config_file | ConvertFrom-StringData
        $accept_license = "false"
        $accept_license = $config.RSP_LICENSE_ACCEPTED.ToLower()

        # Check the value of accept_license
        if ($accept_license -eq "true") {
            Write-Host "License accepted. Performing required action..."
            Perform-LA-Acceptance
        } elseif ($accept_license -eq "false") {
            if (Test-Path $license_file) {
                # Read license text from file
                $license_text = Get-Content $license_file -Raw
                Write-Host ""
                Write-Host "$license_text"

                # Prompt the user to accept the license
                $response = Read-Host "Do you accept the license? (yes/no)"
                $response_lc = $response.ToLower()

                $status=3

                if ($response_lc -eq "yes") {
                    Write-Host "License accepted. Performing required action..."
                    Perform-LA-Acceptance
                } elseif ($response_lc -eq "no") {
                    Write-Host "License not accepted. Exiting..."
                    $status=3
                    exit 1
                    # You can add further actions if needed
                } else {
                    $status=3
                    echo "Invalid response. Please type 'yes' or 'no'."
                    exit 1
                }


            } else {
                $status=3
                echo "License file not found in the script's directory."
                exit 1
            }

        } else {
            echo "Invalid value for accept_license in the config file."
            exit 1
        }
    } else {
        echo "License Config file not found."
        exit 1
    }
    # Create the content for the status.dat file
    $timestamp = Get-Date -Format "#ddd MMM dd HH:mm:ss yyyy"
    $content = "$timestamp`nStatus=$global:status"

    if (-not (Test-Path $user_home_li_dir)){
        New-Item -ItemType Directory -Path $user_home_li_dir
        # Grant full access (all rights to all users)
        icacls $user_home_li_dir /grant "Everyone:F"
    }
    if (-not (Test-Path $status_file)) {
        echo "Thank You..."
    }

    # Write the content to the status.dat file
    Set-Content -Path $status_file -Value $content -Force
    cat $status_file
}

function Get-Heap-Size-MB {
    # Get total memory size
    $total_memory_bytes = 16777216000
    if ($env:OS -eq "Windows_NT") {
		if (Get-Command wmic -ErrorAction SilentlyContinue) {
   			$total_memory_bytes = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory
		} else {
			$total_memory_bytes = $(powershell -command "(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory")
		}
        $total_memory_mb = [math]::Round($total_memory_bytes / 1MB)
    } else {
		if (Get-Command wmic -ErrorAction SilentlyContinue) {
   			$total_memory_bytes = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory
		} else {
			$total_memory_bytes = $(powershell -command "(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory")
		}
        $total_memory_mb = [math]::Round($total_memory_bytes / 1MB)
    }

    # Calculate heap size as a percentage of total memory (75%)
    $heap_size_mb = [math]::Round($total_memory_mb * 0.75)

    # Print total memory and heap size
    Write-Host "Total Memory: ${total_memory_mb} MB"
    Write-Host "Calculated Heap Size: ${heap_size_mb} MB"

    # Return the calculated heap size
    return $heap_size_mb
}

# Main Execution Logic
if (Test-Path $swidtag_file) {
    if (Test-Path "$swidtag_dir\$swidtag") {
        Write-Host "Swidtag file already present."
    } else {
        Copy-Item -Path (Join-Path $script_dir "swidtag") -Destination "$HOME\qs-explorer" -Recurse
    }
	if (Test-Path $config_file) {
	# Read properties from the configuration file
        $config = Get-Content $config_file | ConvertFrom-StringData
        $vulnerability_config_path = ""
		if ($config.VULNERABILITY_CONFIG_PATH) {
			$vulnerability_config_path = $config.VULNERABILITY_CONFIG_PATH
		}
	}
    if (Test-Path $status_file) {
        $status_content = Get-Content -Path $status_file | ConvertFrom-StringData

        if ($status_content.Status -eq "9") {
            Write-Host "License Agreement has already been completed."
            $heap_size = Get-Heap-Size-MB
            Write-Host "Using Heap Size: ${heap_size} MB"
			if ($vulnerability_config_path -ne "") {
				& java -Xmx"${heap_size}m" -Xms2g -Xmn1g -Xss2m -XX:+UseG1GC "-Dfile.encoding=UTF-8" -cp "lib\*" com.ibm.quantumsafe.lang.driver.CryptoCli -vp "$vulnerability_config_path" @args
			}else{
				& java -Xmx"${heap_size}m" -Xms2g -Xmn1g -Xss2m -XX:+UseG1GC "-Dfile.encoding=UTF-8" -cp "lib\*" com.ibm.quantumsafe.lang.driver.CryptoCli @args
			}
        } else {
            Check-For-License
        }
    } else {
        Write-Host "License Agreement has not been accepted. Please accept the license agreement to continue."
        Check-For-License
    }
    if($global:license_accepted -eq "true") {
        $heap_size = Get-Heap-Size-MB
        Write-Host "Using Heap Size: ${heap_size} MB"
        if ($vulnerability_config_path -ne "") {
                & java -Xmx"${heap_size}m" "-Xms2g" "-Xmn1g" "-Xss2m" "-XX:+UseG1GC" "-Dfile.encoding=UTF-8" -cp "lib\*" "com.ibm.quantumsafe.lang.driver.CryptoCli" -vp "$vulnerability_config_path" $args
			}else{
				& java -Xmx"${heap_size}m" "-Xms2g" "-Xmn1g" "-Xss2m" "-XX:+UseG1GC" "-Dfile.encoding=UTF-8" -cp "lib\*" "com.ibm.quantumsafe.lang.driver.CryptoCli" $args
			}
    }
} else {
    Write-Host "License Agreement swidtag file not found. Please update the project with the latest data files."
}
