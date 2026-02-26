#!/bin/bash
# TODO: Create functions, for all the repeating code

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SESSION_MANAGER="$SCRIPT_DIR/session_manager.py"

export ATMUX_SESSIONS_FILE="$HOME/.config/atmux/sessions.json"

SESSION_NAME="default"
if [ ! -z "$1" ]; then
	SESSION_NAME="$1"
fi

MANUAL_CREATION=false

OPTIONS=""
# TODO: Add options like in tmux (ls, delete, rename, etc)
# NOTE: Maybe do manual creation, still thinking about it

# get option flags
while getopts "a:m" opts; do
	case $opts in
		a)
			if [ ! -z "$OPTARG" ]; then
				OPTIONS="$OPTARG"
			fi
			;;
		m)
			MANUAL_CREATION=true
			;;
	esac
done

# Get tmux sessions
echo "Getting existing tmux sessions"
EXISTING_SESSIONS=$(tmux list-sessions -F "#{session_name} #{session_attached}" 2>/dev/null)

# Look whether there even is an active tmux server
if [ -z "$EXISTING_SESSIONS" ]; then
	echo "No active tmux server -> setting all sessions to not running"
	python3 "$SESSION_MANAGER" "set-all-running-false"
else
	echo "Comparing running sessions against running in file"
	PRESUMED_RUNNING=$(python3 "$SESSION_MANAGER" "get-running-all")
	read -r -a PRESUMED_RUNNING_ITEMS <<< "$PRESUMED_RUNNING"

	# Check whether in save there are running sessions that don't even exist in the server
	for PRESUMED_RUNNING_ITEM in "${PRESUMED_RUNNING_ITEMS[@]}"; do
		if [[ " $EXISTING_SESSIONS " != *" $PRESUMED_RUNNING_ITEM "* ]]; then
			python3 "$SESSION_MANAGER" "set-running" "$PRESUMED_RUNNING_ITEM" "False"
		fi
	done

	# Update the running and non-running sessions in file against actual tmux server
	while read -r EXISTING_SESSION_NAME IS_RUNNING; do
		if [ "$IS_RUNNING" -gt 0 ]; then
			python3 "$SESSION_MANAGER" "set-running" "$EXISTING_SESSION_NAME" "True"
		else
			python3 "$SESSION_MANAGER" "set-running" "$EXISTING_SESSION_NAME" "False"
		fi
	done <<< "$EXISTING_SESSIONS" # feeds the data into the loop
fi

# Check whether Session already exists
TMUX_CURRENT_SESSIONS=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | tr '\n' ' ') # change \n into space seperation -> create flat string
FILE_HAS_SESSION=$(python3 "$SESSION_MANAGER" "check" "$SESSION_NAME")
SESSION_EXISTS=false

SESSION_PATH=$PWD
WINDOW_COUNT=1
WINDOW_NAMES="zsh"

if [ ! -z "$TMUX_CURRENT_SESSIONS" ]; then
	if [[ " $TMUX_CURRENT_SESSIONS " == *" $SESSION_NAME "* ]]; then
		SESSION_EXISTS=true
	fi
else
	SESSION_EXISTS=false
fi

if [ "$SESSION_EXISTS" = "true" ]; then
	if [ "$FILE_HAS_SESSION" = "True" ]; then
		IS_SESSION_RUNNING=$(python3 "$SESSION_MANAGER" "get-running" "$SESSION_NAME")

		if [ "$IS_SESSION_RUNNING" = "True" ]; then
			echo "Session is already running"
			echo "Stopping atmux process, please detach safely through tmux"
			
			exit
		else
			# Check for the $TMUX variable
			if [ ! -z "$TMUX" ]; then
				echo "We are in a session"
				echo "Switching session"
				python3 "$SESSION_MANAGER" "set-running" "$SESSION_NAME" "True"

				tmux switch-client -t "$SESSION_NAME"

				python3 "$SESSION_MANAGER" "set-running" "$SESSION_NAME" "False"
			else
				echo "Attaching session"
				python3 "$SESSION_MANAGER" "set-running" "$SESSION_NAME" "True"

				tmux attach -t $SESSION_NAME # will pause script here, waiting for detach or exit

				python3 "$SESSION_MANAGER" "set-running" "$SESSION_NAME" "False"
			fi
		fi
	else
		echo "Creating session in file"
		# Session path
		SESSION_PATHS=$(tmux list-sessions -F "#{session_name} #{session_path}" 2>/dev/null)
		while read TMUX_SESSION_NAME TMUX_SESSION_PATH; do
			if [ "$TMUX_SESSION_NAME" = "$SESSION_NAME" ]; then
				SESSION_PATH="$TMUX_SESSION_PATH"
			fi
		done <<< "$SESSION_PATHS"

		# Window count
		WINDOW_NAMES=$(tmux list-windows -t "$SESSION_NAME" -F \#W 2>/dev/null | tr '\n' ' ')
		WINDOW_COUNT=$(wc -w <<< "$WINDOW_NAMES") # wc -> word count

		# set in file
		python3 "$SESSION_MANAGER" "set" "$SESSION_NAME" "$SESSION_PATH" "$WINDOW_COUNT" "$WINDOW_NAMES"

		# Check whether session is actually already running
		while read TMUX_SESSION_NAME IS_RUNNING; do
			if [ "$TMUX_SESSION_NAME" = "$SESSION_NAME" ]; then
				if [ "$IS_RUNNING" -gt 0]; then
					echo "Session is already running, but now also exists in file, good job ;)"
					echo "Stopping this atmux process"
					echo "Please detach safely through tmux"

					exit
				fi
			fi
		done <<< "$EXISTING_SESSIONS"

		# Check for the $TMUX variable
		if [ ! -z "$TMUX" ]; then
			echo "We are in a session"
			echo "Switching session"
			python3 "$SESSION_MANAGER" "set-running" "$SESSION_NAME" "True"

			tmux switch-client -t "$SESSION_NAME"

			python3 "$SESSION_MANAGER" "set-running" "$SESSION_NAME" "False"
		else
			echo "Attaching to session"
			python3 "$SESSION_MANAGER" "set-running" "$SESSION_NAME" "True"
			
			tmux attach -t "$SESSION_NAME"

			python3 "$SESSION_MANAGER" "set-running" "$SESSION_NAME" "True"
		fi 
	fi
else
	if [ "$FILE_HAS_SESSION" = "True" ]; then
		# get session details
		SESSION_PATH=$(python3 "$SESSION_MANAGER" "get-session-path" "$SESSION_NAME")
		WINDOW_COUNT=$(python3 "$SESSION_MANAGER" "get-window-count" "$SESSION_NAME")
		WINDOW_NAMES=$(python3 "$SESSION_MANAGER" "get-window-names" "$SESSION_NAME")

		# create tmux session
		echo "Creating tmux session from file"
		tmux new-session -d -s "$SESSION_NAME" -c "$SESSION_PATH"
		read -r -a WINDOW_NAMES_ARRAY <<< "$WINDOW_NAMES"

		for (( WINDOW_NUMBER=1; WINDOW_NUMBER<=WINDOW_COUNT; WINDOW_NUMBER++ )); do
			if [ "$WINDOW_NUMBER" = "1" ]; then
				tmux rename-window -t "$SESSION_NAME":"$WINDOW_NUMBER" "${WINDOW_NAMES_ARRAY[$WINDOW_NUMBER-1]}"
			else
				tmux new-window -t "$SESSION_NAME" -n "${WINDOW_NAMES_ARRAY[$WINDOW_NUMBER-1]}"
			fi
		done

		# Checking for TMUX session
		if [ ! -z "$TMUX" ]; then
			echo "We are in a session"
			echo "Switching session"
			python3 "$SESSION_MANAGER" "set-running" "$SESSION_NAME" "True"

			tmux switch-client -t "$SESSION_NAME"

			python3 "$SESSION_MANAGER" "set-running" "$SESSION_NAME" "False"
		else
			echo "Attaching tmux session"
			python3 "$SESSION_MANAGER" "set-running" "$SESSION_NAME" "True"
			
			tmux attach -t "$SESSION_NAME"

			python3 "$SESSION_MANAGER" "set-running" "$SESSION_NAME" "False"
		fi
	else
		echo "Creating default tmux session"
		tmux new-session -d -s "$SESSION_NAME" -c "$SESSION_PATH"
		python3 "$SESSION_MANAGER" "set" "$SESSION_NAME" "$SESSION_PATH" "$WINDOW_COUNT" "$WINDOW_NAMES"

		if [ ! -z "$TMUX" ]; then
			echo "We are in a session"
			echo "Switching session"
			python3 "$SESSION_MANAGER" "set-running" "$SESSION_NAME" "True"

			tmux switch-client -t "$SESSION_NAME"

			python3 "$SESSION_MANAGER" "set-running" "$SESSION_NAME" "False"
		else
			echo "Attaching to session"
			python3 "$SESSION_MANAGER" "set-running" "$SESSION_NAME" "True"
			
			tmux attach -t "$SESSION_NAME"

			python3 "$SESSION_MANAGER" "set-running" "$SESSION_NAME" "False"
		fi
	fi
fi

EXISTING_SESSIONS=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | tr '\n' ' ')
ANSWER="n"

if [[ " $EXISTING_SESSIONS " != *" $SESSION_NAME "* ]]; then
	echo "You have exited the current session, do you want to delete the session from file? [y/n]"
	read ANSWER

	if [ "$ANSWER" = "y" ]; then
		python3 "$SESSION_MANAGER" "delete" "$SESSION_NAME"
	fi

	
else
	WINDOW_NAMES=$(tmux list-windows -t "$SESSION_NAME" -F \#W 2>/dev/null | tr '\n' ' ')
	WINDOW_COUNT=$(wc -w <<< "$WINDOW_NAMES")

	python3 "$SESSION_MANAGER" "set-windows" "$SESSION_NAME" "$WINDOW_COUNT" "$WINDOW_NAMES"
fi
