#!/bin/bash

# Help flag
if [ "$1" == "-h" ]; then
    echo "Usage:"
    echo "  -id [PID part]   Search by PID"
    echo "  -n  [name]       Search by process name"
    exit
fi

# Get process list based on flag
if [ "$1" == "-id" ]; then
    results=$(ps -eo pid,comm,state,%cpu | grep "$2")
elif [ "$1" == "-n" ]; then
    results=$(ps -eo pid,comm,state,%cpu | grep -i "$2")
else
    echo "Invalid option. Use -h for help."
    exit
fi

# Check if empty
[ -z "$results" ] && echo "No matches found." && exit

echo "Results:"
echo "----------------------"

# Print numbered list
i=1
echo "$results" | while read line; do
    echo "$i) $line"
    ((i++))
done

echo "----------------------"
echo "Enter number(s) to kill:"
read choices

# Convert results into array
mapfile -t lines <<< "$results"

for num in $choices; do
    line="${lines[$((num-1))]}"
    pid=$(echo "$line" | awk '{print $1}')

    echo "Killing PID: $pid"
    echo "$pid" | xargs kill
done
