#!/bin/bash
# src/attendance.sh

get_attendance() {
    local group=$1
    local group_file="data/students/groups/${group}"
    
    if [[ ! -f "$group_file" ]]; then
        echo "Ошибка: список группы '$group' не найден." >&2
        return 1
    fi

    cat "$group_file" | xargs -I {} sh -c '
        count=$(grep -h "^{} " data/*/"'"${group}"'-attendance" 2>/dev/null | tr -cd "1" | wc -c)
        echo "$count {}"
    ' | sort -rn | sed 's/^\([0-9]*\) \(.*\)/\2 \1 посещений/'
}