#!/bin/bash

# check that we can call stress-ng
if ! command -v stress-ng &> /dev/null
then
   echo "stress-ng could not be found. Please install or check /usr/local/bin path".
   exit 1
fi

# default parameters for stress tests
stress_duration=60   # stress test duration in seconds
stress_workers=4     # number of workers to spawn for the stress test
log_file="stress_load.log"

# handle passing in parameters with calling the script
stress_duration="${1:-$stress_duration}"
stress_workers="${2:-$stress_workers}"

echo "Starting stress-ng with $stress_workers workers for $stress_duration seconds..."

# log system load to file
log_load() {
   current_time=$(date '+%Y-%m-%d %H:%M:%S')

   load_1min=$(awk '{print $1}' /proc/loadavg)
   load_5min=$(awk '{print $2}' /proc/loadavg)
   load_15min=$(awk '{print $3}' /proc/loadavg)

   # log to log_file
   echo "$current_time | Load (1m): $load_1min | Load (5m): $load_5min | Load (15m): $load_15min" >> "$log_file"
}

# report the system load
report_load() {
   echo "System Load Report at $(date):"
   uptime
}

# run stress-ng in the background
stress-ng --cpu $stress_workers --timeout ${stress_duration}s --oom-avoid &

# store the stress-ng process ID
stress_pid=$!

# initialize log file
echo "Starting stress test at $(date)" > "$log_file"

# periodically report system load during the stress test
interval=5   # interval in seconds between each load report
end_time=$(($(date +%s) + stress_duration))

while [ $(date +%s) -lt $end_time ]; do
   report_load
   sleep $interval
done

# wait for the stress-ng process to finish
wait $stress_pid

echo "Stress test complete."
