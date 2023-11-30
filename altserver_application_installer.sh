#!/bin/bash

# Function to check if a process is running
is_process_running() {
  pgrep -x "$1" > /dev/null
}

# Function to start Anisette server
start_anisette_server() {
  nohup ./anisette-server -n 127.0.0.1 -p 6969 > /dev/null 2>&1 &
}

# Clear the terminal screen
clear

# Check if Anisette is already running and restart it if necessary
if is_process_running "anisette-server"; then
  echo "Anisette server is already running. Restarting..."
  pkill anisette-server
  sleep 2
  clear
fi

# Check if the required -u and -p flags are provided
if [[ "$#" -eq 0 || "$#" -ne 4 || "$1" != "-u" || "$3" != "-p" ]]; then
  echo "Usage: $0 -u <username> -p <password>"
  exit 1
fi

# Start the Anisette server in a subshell and continue with the script
(
  start_anisette_server

  # Export the Anisette server details to the environment
  export ALTSERVER_ANISETTE_SERVER=http://127.0.0.1:6969

  # Sleep for a moment to allow the server to start (you can adjust the duration as needed)
  sleep 5

  # Check if there are files in the "install" folder
  if [ ! -f "install"/* ]; then
    echo "No files found in the 'install' folder. Script canceled."
    pkill anisette-server
    exit 1
  fi

  # Get the username and password from command line arguments
  USERNAME="$2"
  PASSWORD="$4"

  # Run lsusb and save the iSerial number to the DEVICE variable
  DEVICE=$(lsusb -v 2> /dev/null | awk '/Apple Inc/{flag=1;next} flag && /iSerial/{print $3;exit}')

  # Check if a device with iSerial is found
  if [ -z "$DEVICE" ]; then
    echo "No Apple device found. Script canceled."
    pkill anisette-server
    exit 1
  fi

  # Loop through the "install" folder and run the final command with the dynamic iSerial
  for file in install/*; do
    if [ -f "$file" ]; then
      ./AltServer -u "$DEVICE" -a "$USERNAME" -p "$PASSWORD" "$file"
    fi
  done

  # Kill the Anisette server
  pkill anisette-server

  # Clear the terminal screen
  clear

  # Display a success message
  echo "Script completed successfully."
)
