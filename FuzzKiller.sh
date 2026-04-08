#!/bin/bash

# -----------------------------
# HELP MENU
# -----------------------------
show_help() {
    echo "================ FUZZY KILL HELP ================"
    echo ""
    echo "This tool helps you find and terminate processes"
    echo "using fuzzy (partial) matching."
    echo ""
    echo "OPTIONS:"
    echo "  1) Search by PID"
    echo "  2) Search by process name"
    echo "  3) Show all running processes"
    echo ""
    echo "WORKFLOW:"
    echo "  - Choose an option"
    echo "  - Review results"
    echo "  - Select process number(s) to kill"
    echo ""
    echo "COMMANDS USED:"
    echo "  ps, grep, awk, xargs, kill"
    echo ""
    echo "================================================="
}

# -----------------------------
# MAIN LOOP
# -----------------------------
while true; do

    echo ""
    echo "=================================="
    echo "        FUZZY PROCESS KILL        "
    echo "=================================="
    echo "1) Search by PID"
    echo "2) Search by Process Name"
    echo "3) Show ALL Processes"
    echo "4) Help"
    echo "5) Exit"
    echo ""

    read -p "Enter choice: " choice

    case $choice in
        1)
            read -p "Enter part of PID: " search
            results=$(ps aux | grep "$search" | grep -v grep)
            ;;
        2)
            read -p "Enter process name: " search
            results=$(ps aux | grep -i "$search" | grep -v grep)
            ;;
        3)
            echo "[*] Showing processes..."
            results=$(ps aux | head -n 25)
            ;;
        4)
            show_help
            continue
            ;;
        5)
            echo "Goodbye."
            exit
            ;;
        *)
            echo "Invalid option."
            continue
            ;;
    esac

    # -----------------------------
    # CHECK RESULTS
    # -----------------------------
    if [ -z "$results" ]; then
        echo "No matches found."
        continue
    fi

    # -----------------------------
    # DISPLAY RESULTS
    # -----------------------------
    echo ""
    echo "Results:"
    echo "-------------------------------------------------------------"

    mapfile -t lines <<< "$results"

    printf "%-3s %-8s %-10s %-6s %-20s\n" "#" "PID" "USER" "CPU%" "COMMAND"
    echo "-------------------------------------------------------------"

    for i in "${!lines[@]}"; do
        pid=$(echo "${lines[$i]}" | awk '{print $2}')
        user=$(echo "${lines[$i]}" | awk '{print $1}')
        cpu=$(echo "${lines[$i]}" | awk '{print $3}')
        cmd=$(echo "${lines[$i]}" | awk '{print $11}')

        printf "%-3s %-8s %-10s %-6s %-20s\n" "$((i+1))" "$pid" "$user" "$cpu" "$cmd"
    done

    echo "-------------------------------------------------------------"
    read -p "Enter number(s) to kill (or press Enter to cancel): " choices

    # -----------------------------
    # KILL SELECTED
    # -----------------------------
    for num in $choices; do
        line="${lines[$((num-1))]}"
        pid=$(echo "$line" | awk '{print $2}')

        if [ -n "$pid" ]; then
            echo "Killing PID: $pid"
            echo "$pid" | xargs kill 2>/dev/null
        fi
    done

done
