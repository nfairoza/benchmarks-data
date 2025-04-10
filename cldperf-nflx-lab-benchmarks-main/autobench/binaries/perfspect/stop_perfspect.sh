#!/bin/bash
# This script stops the perfspect metrics and telemetry processes and their children

# Find the PIDs of the perfspect metrics and telemetry processes
PERF_PIDS=$(pgrep -f "./binaries/perfspect/perfspect (metrics|telemetry)")

if [ -z "$PERF_PIDS" ]; then
    echo "Perfspect metrics or telemetry processes not found. Are they running?"
    exit 1
fi

echo "Found perfspect metrics and telemetry processes with PIDs:"
echo "$PERF_PIDS" | xargs

# Convert the newline-separated list of PIDs into an array
IFS=$'\n' read -r -d '' -a PID_ARRAY <<< "$PERF_PIDS"

# Function to terminate process groups
terminate_process_groups() {
    local PIDS=("$@")
    echo "Terminating process groups for PIDs: ${PIDS[*]}"
    for PID in "${PIDS[@]}"; do
        # Get the full command line for the process
        CMD_LINE=$(ps -p "$PID" -o args=)
        echo "PID: $PID, Command: $CMD_LINE"

        # Get the process group ID (PGID) of the process
        PGID=$(ps -o pgid= -p "$PID" | grep -o '[0-9]*')
        if [ -n "$PGID" ]; then
            # Send SIGINT to the process group
            echo "Sending SIGINT to process group with PGID: $PGID (Command: $CMD_LINE)"
            kill -INT -"$PGID"

            # Wait a few seconds to allow the processes to terminate
            sleep 5

            # Check if the process group is still running and forcefully kill it if necessary
            if ps -o pgid= -p "$PID" | grep -q "$PGID"; then
                echo "Process group still running, sending SIGKILL to PGID: $PGID (Command: $CMD_LINE)"
                kill -KILL -"$PGID"
            else
                echo "Process group terminated successfully for PGID: $PGID (Command: $CMD_LINE)."
            fi
        else
            echo "Could not find PGID for PID: $PID (Command: $CMD_LINE)"
        fi
    done
}

# Terminate all perfspect-related process groups
terminate_process_groups "${PID_ARRAY[@]}"

echo "All perfspect metrics and telemetry processes have been terminated."
