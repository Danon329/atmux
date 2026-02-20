#!/bin/bash

exec 200>/tmp/atmux.lock

MANUAL_CREATION=false
SESSION_NAME="0"

SESSION_PATH=$PWD
NUMBER_WINDOWS=1
declare -a WINDOW_NAMES # that should create an Array I think

# get option flags
while getopts "s:m" opts; do
	case $opts in
		s)
			if [ ! -z "$OPTARG" ]; then
				SESSION_NAME=$OPTARG
			fi
			;;
		m)
			MANUAL_CREATION=true
			;;
	esac
done

# Start file lock
flock 200

# Get tmux sessions
EXISTING_SESSIONS=$(tmux list-sessions -F "#{session_name} #{session_attached}" 2>dev/null)

# Look whether there even is an active tmux server
if [ -z "$EXISTING_SESSIONS "]; then
	python3 session_manager.py set_all_running_false
else
	PRESUMED_RUNNING=$(python3 session_manager.py get-running-all)
	read -r -a PRESUMED_RUNNING_ITEMS <<< "$PRESUMED_RUNNING"

	# Check whether in save there are running sessions that don't even exist in the server
	for PRESUMED_RUNNING_ITEM in "${PRESUMED_RUNNING_ITEMS[@]}"; do
		if [[ " $EXISTING_SESSIONS " != *" $PRESUMED_RUNNING_ITEM "* ]]; then
			python3 session_manager.py set_running $PRESUMED_RUNNING_ITEM False
		fi
	done

	# Update the running and non-running sessions in file against actual tmux server
	while read -r EXISTING_SESSION_NAME IS_RUNNING; do
		if ["$IS_RUNNING" -gt 0]; then
			python3 session_manager.py set_running $EXISTING_SESSION_NAME True
		else
			python3 session_manager.py set_running $EXISTING_SESSION_NAME False
		fi
	done <<< "$EXISTING_SESSIONS" # feeds the data into the loop
fi

# TODO: Now think about attachment or creation of needed session

# Check whether Session already exists
TMUX_HAS_SESSION=$(python3 session_manager.py "check" $SESSION_NAME)
IS_SESSION_RUNNING=$(python3 session_manager.py "get-running" $SESSION_NAME)

if [ "$TMUX_HAS_SESSION" = "True" ]; then
	if [ "$IS_SESSION_RUNNING" = "True" ]; then
		echo "Session is already running"
		echo "Hope you called through atmux for running control"
		flock -u 200
	else
		# TODO:
		# set running to true
		# attach tmux
		# set running to false
	fi
else
	# TODO:
	# Create session, check for no manual session creation (I don't want to think about that currently)
	# Check whether session already exists in serialized form, then get details and create session
	# Else make default creation
fi

# TODO:
# First check for "active" tmux sessions (detached and attached)
# if current session was exited, prompt whether want to delete from serialization or not
# if delete, delete from file
# else:
# After detaching, get windows of current session, to serialize in file, with the names
