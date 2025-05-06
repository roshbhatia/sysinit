#!/bin/bash
# shellcheck disable=all
height=32

while [[ $# -gt 0 ]]; do
    case $1 in
        --height)
            height="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

tput sc
tput civis
trap 'tput cnorm; tput rc; tput ed; exit' INT TERM EXIT

declare -a lines=()
for ((i=0; i<height; i++)); do
    lines[i]=""
done

redraw_display() {
    tput rc
    tput ed
    
    for ((i=0; i<${#lines[@]}; i++)); do
        if [[ -n "${lines[i]}" ]]; then
            echo "| ${lines[i]}"
        fi
    done
}

line_count=0
while IFS= read -r line; do
    if [[ $line_count -ge $height ]]; then
        for ((i=0; i<height-1; i++)); do
            lines[i]="${lines[i+1]}"
        done
        lines[$((height-1))]="$line"
    else
        lines[$line_count]="$line"
        ((line_count++))
    fi
    
    redraw_display
done

exit 0
