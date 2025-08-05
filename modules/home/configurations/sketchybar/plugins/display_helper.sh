#!/usr/bin/env bash

# Display helper functions for sketchybar

get_display_info() {
    system_profiler SPDisplaysDataType | grep -A5 "Built-in" | head -10
}

has_notch() {
    # Check if display has a notch by looking for specific MacBook models
    local model=$(system_profiler SPHardwareDataType | grep "Model Name" | cut -d: -f2 | xargs)

    case "$model" in
        *"MacBook Pro"*)
            # MacBook Pro models with notch (14" and 16" from 2021+)
            local year=$(system_profiler SPHardwareDataType | grep "Model Identifier" | grep -o "MacBookPro[0-9]*,[0-9]*" | cut -d, -f1 | grep -o "[0-9]*")
            if [ "$year" -ge 18 ]; then  # MacBookPro18,x and higher have notch
                echo "true"
            else
                echo "false"
            fi
            ;;
        *)
            echo "false"
            ;;
    esac
}

get_safe_area() {
    if [ "$(has_notch)" = "true" ]; then
        echo "notch"
    else
        echo "standard"
    fi
}

get_bar_position() {
    local safe_area="$1"
    if [ "$safe_area" = "notch" ]; then
        echo "top"
    else
        echo "top"
    fi
}

get_bar_margin() {
    local safe_area="$1"
    if [ "$safe_area" = "notch" ]; then
        echo "10"  # More margin for notched displays
    else
        echo "5"   # Standard margin
    fi
}

get_bar_padding() {
    local safe_area="$1"
    if [ "$safe_area" = "notch" ]; then
        echo "15"  # More padding around notch
    else
        echo "10"  # Standard padding
    fi
}
