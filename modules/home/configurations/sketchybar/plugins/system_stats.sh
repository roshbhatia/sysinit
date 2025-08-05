#!/usr/bin/env bash

# System stats plugin (CPU, Memory, Network)

get_cpu_usage()
                {
    top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | cut -d% -f1 2> /dev/null || echo "0"
}

get_memory_usage()
                   {
    local memory_info=$(vm_stat 2> /dev/null)
    if [ -n "$memory_info" ]; then
        local pages_free=$(echo "$memory_info" | grep "Pages free" | awk '{print $3}' | cut -d. -f1)
        local pages_active=$(echo "$memory_info" | grep "Pages active" | awk '{print $3}' | cut -d. -f1)
        local pages_inactive=$(echo "$memory_info" | grep "Pages inactive" | awk '{print $3}' | cut -d. -f1)
        local pages_speculative=$(echo "$memory_info" | grep "Pages speculative" | awk '{print $3}' | cut -d. -f1)
        local pages_wired=$(echo "$memory_info" | grep "Pages wired down" | awk '{print $4}' | cut -d. -f1)

        local total_pages=$((pages_free + pages_active + pages_inactive + pages_speculative + pages_wired))
        local used_pages=$((pages_active + pages_inactive + pages_speculative + pages_wired))

        if [ "$total_pages" -gt 0 ]; then
            echo $((used_pages * 100 / total_pages))
    else
            echo "0"
    fi
  else
        echo "0"
  fi
}

get_network_status()
                     {
    # Check for active network interface
    if ping -c 1 -W 1000 8.8.8.8 > /dev/null 2>&1; then
        echo "online"
  else
        echo "offline"
  fi
}

case "$1" in
    "cpu")
        CPU_USAGE=$(get_cpu_usage)
        if [ "$CPU_USAGE" -gt 80 ]; then
            COLOR="0xffed8796"  # Red
    elif     [ "$CPU_USAGE" -gt 60 ]; then
            COLOR="0xfff5a97f"  # Orange
    else
            COLOR="0xffa5adcb"  # Default
    fi
        sketchybar --set "$NAME" \
                   icon="" \
                   label="$CPU_USAGE%" \
                   icon.color="$COLOR"
        ;;

    "memory")
        MEMORY_USAGE=$(get_memory_usage)
        if [ "$MEMORY_USAGE" -gt 80 ]; then
            COLOR="0xffed8796"  # Red
    elif     [ "$MEMORY_USAGE" -gt 60 ]; then
            COLOR="0xfff5a97f"  # Orange
    else
            COLOR="0xffa5adcb"  # Default
    fi
        sketchybar --set "$NAME" \
                   icon="" \
                   label="$MEMORY_USAGE%" \
                   icon.color="$COLOR"
        ;;

    "network")
        NETWORK_STATUS=$(get_network_status)
        if [ "$NETWORK_STATUS" = "online" ]; then
            ICON=""
            COLOR="0xffa6da95"  # Green
            LABEL="Online"
    else
            ICON=""
            COLOR="0xffed8796"  # Red
            LABEL="Offline"
    fi
        sketchybar --set "$NAME" \
                   icon="$ICON" \
                   label="$LABEL" \
                   icon.color="$COLOR"
        ;;

    *)
        echo "Usage: $0 {cpu|memory|network}"
        exit 1
        ;;
esac
