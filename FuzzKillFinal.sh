#!/bin/bash

# ============================================================
# FUZZY KILL SCRIPT
# A simple interactive tool to find and kill processes
# using partial (fuzzy) matching.
# ============================================================


# -----------------------------
# HELP / MAN PAGE FUNCTION
# -----------------------------
show_help() {
    echo "================ FUZZY KILL MAN PAGE ================"
    echo ""
    echo "NAME:"
    echo "  fuzzykill - interactive fuzzy process killer"
    echo ""
    echo "DESCRIPTION:"
    echo "  This script allows you to search for running processes"
    echo "  using partial matches (PID or name), then select which"
    echo "  ones to terminate from a numbered list."
    echo ""
    echo "USAGE:"
    echo "  Run the script and choose an option from the menu."
    echo ""
    echo "OPTIONS:"
    echo "  1  Search by PID (partial match)"
    echo "  2  Search by process name (partial match)"
    echo "  3  Show all running processes (sorted by CPU)"
    echo "  4 Show this help menu"
    echo ""
    echo "IMPORTANT:"
    echo "  When selecting a process to kill, you MUST use the"
    echo "  NUMBER from the displayed list — NOT the PID."
    echo ""
    echo "  Example:"
    echo "    1   1234  bash"
    echo "    2   5678  python"
    echo ""
    echo "  To kill 'bash', enter: 1"
    echo "  (NOT 1234)"
    echo ""
    echo "NOTES:"
    echo "  - Some system processes may restart automatically"
    echo "    because they are managed by system services."
    echo "  - Be careful when killing unknown processes."
    echo ""
    echo "COMMANDS USED:"
    echo "  ps, grep, awk, xargs, kill"
    echo ""
    echo "===================================================="
}

# -----------------------------
# MAIN LOOP (keeps script running)
# -----------------------------
while true; do

    # Display menu every loop
    echo ""
    echo "=================================="
    echo "        FUZZY PROCESS KILL        "
    echo "=================================="
    echo "1) Search by PID"
    echo "2) Search by Process Name"
    echo "3) Show ALL Processes (sorted by CPU)"
    echo "4) Help"
    echo "5) Exit"
    echo ""

    # Read user input
    read -p "Enter choice: " choice

    # Variable to store process results
    results=""

    # -----------------------------
    # MENU LOGIC
    # -----------------------------
    case $choice in
        1)
            # Ask user for partial PID
            read -p "Enter part of PID: " search

            # Get process list, sort by CPU, then filter by PID match
            results=$(ps -eo pid,comm,state,%cpu --no-headers --sort=-%cpu | grep "$search")
            ;;
        2)
            # Ask user for process name
            read -p "Enter process name: " search

            # Case-insensitive search for process names
            results=$(ps -eo pid,comm,state,%cpu --no-headers --sort=-%cpu | grep -i "$search")
            ;;
        3)
            # Show top 25 processes sorted by CPU usage
            echo "[*] Showing running processes (sorted by CPU)..."
            results=$(ps -eo pid,comm,state,%cpu --no-headers --sort=-%cpu | head -n 25)
            ;;
        4)
            # Show help page
            show_help
            continue
            ;;
        5)
            # Exit the script
            echo "Goodbye."
            exit
            ;;
        *)
            # Handle invalid input
            echo "Invalid option."
            continue
            ;;
    esac

    # -----------------------------
    # CHECK IF RESULTS EXIST
    # -----------------------------
    if [ -z "$results" ]; then
        echo "No matches found."
        continue
    fi

    # -----------------------------
    # DISPLAY RESULTS IN TABLE FORMAT
    # -----------------------------
    echo ""
    echo "Results:"
    echo "------------------------------------------------------"

    # Convert results into an array for indexing
    mapfile -t lines <<< "$results"

    # Print table header
    printf "%-3s %-7s %-20s %-6s %-6s\n" "#" "PID" "NAME" "STATE" "CPU%"
    echo "------------------------------------------------------"

    # Loop through each result and format nicely
    for i in "${!lines[@]}"; do

        # Extract fields using awk
        pid=$(echo "${lines[$i]}" | awk '{print $1}')
        name=$(echo "${lines[$i]}" | awk '{print $2}')
        state=$(echo "${lines[$i]}" | awk '{print $3}')
        cpu=$(echo "${lines[$i]}" | awk '{print $4}')

        # Print formatted row
        printf "%-3s %-7s %-20s %-6s %-6s\n" "$((i+1))" "$pid" "$name" "$state" "$cpu"
    done

    echo "------------------------------------------------------"

    # Prompt user for selection
    echo "NOTE: Enter the LIST NUMBER (not PID)"
    read -p "Enter number(s) to kill (or press Enter to cancel): " choices

    # -----------------------------
    # KILL SELECTED PROCESSES
    # -----------------------------
    for num in $choices; do

        # Get the selected line from array
        line="${lines[$((num-1))]}"

        # Extract PID from that line
        pid=$(echo "$line" | awk '{print $1}')

        # If PID exists, attempt to kill it
        if [ -n "$pid" ]; then
            echo "Killing PID: $pid"
            echo "$pid" | xargs kill 2>/dev/null
        fi
    done

done
