#!/usr/bin/env bash

#---------------------------------------------------------------------------
# Small script to monitor changes of a file or directory.
# 
# -- Requirements
# 
# You need to have git installed on your system because
# it is used to compute and show the changes.
# 
# -- Usage Steps
# 
# 1. Initialize the monitoring of a directory or file using
# 
# $ watcher init <path> 
# 
# This will cache the current state of the given <path>
# Note that when monitoring a directory all files and 
# directories inside it are monitored too.
# 
# 2. Do any changes to the monitored file or directory.
# 
# 3. Check what changed by typing
# 
# $ watcher status <path>
# 
# 4. Update the state of the path and its sub paths
# 
# $ watcher update <path>
# 
# This will update the cache so that only futur changes 
# are shown by the status command.
# 
# 5. Stops the monitoring of a path and clear the cache
# 
# $ watcher clear <path> 
# 
# That's all, enjoy :)
#---------------------------------------------------------------------------

# Config
cache_dir="$HOME/.watcher-cache"

# Check that arguments are given
if [ $# -lt 2 ]; then
	echo "Error: Missing arguments"
    echo "Usage: watcher init|update|status <path>"
    exit 1
fi

# Ensure git is installed
git --version 2>&1 >/dev/null
if [ $? -ne 0 ]; then
	echo "Error: Could not find Git. Watcher requires Git to be present on your system"
	exit 1
fi

# Get arguments
command_name=$1
path=$2

# Check the path
path_type="none"
path_dir="."
if [ -d "$path" ]; then
	path_type="dir"
	path=$(cd "$path" && pwd)
elif [ -f "$path" ]; then
	path_type="file"
	path=$(cd $(dirname "$path") && pwd)"/"$(basename "$path")
fi

if [ "$path_type" == "none" ]; then
	echo "'$path' is not a directory nor a file !"
	exit 1
fi

# Handle the command

cache_path="$cache_dir$path"

if [ "$command_name" == "init" -o "$command_name" == "update" ]; then
	mkdir -p $(dirname "$cache_path")
	cp -rf "$path" "$cache_path"

elif [ "$command_name" == "status" ]; then
	if ! [ -e "$cache_path" ]; then
		echo "Error: Could not find cache for '$path'; please use init to create it"
		exit 1
	fi

	if [ $path_type == "file" ]; then
		# Use git to show the diff
		git diff --no-index "$cache_path" "$path"
	elif [ $path_type == "dir" ]; then
		git diff --no-index --name-status "$cache_path" "$path" | while read line; do
			# Remove the cache_dir from paths
			line=${line/"$cache_dir"/""}
			# Show relative paths
			echo ${line/"$path/"/""}
		done
	else
		echo "Error: Something went really wrong ..."
		exit 1
	fi

elif [ "$command_name" == "clear" ]; then
	rm -rf "$cache_path"

else
	echo "Error: Unknown command $command_name !"
	exit 1
fi