#!/bin/bash
# src/attendance.sh

get_attendance() {
    local group=$1
    local group_file="data/students/groups/${group}"
    
    if [[ ! -f "$group_file" ]]; then
        echo "Ошибка: список группы '$group' не найден." >&2
        return 1
    fi
    
    if [[ ! -s "$group_file" ]]; then
        echo "Ошибка: список группы '$group' пуст." >&2
        return 1
    fi

    local att_file
    att_file=$(find data -type f -name "${group}-attendance" 2>/dev/null | head -n 1)
    
    if [[ -z "$att_file" ]]; then
        echo "Ошибка: файл посещаемости для группы '$group' не найден." >&2
        return 1
    fi
    
    cat "$group_file" | xargs -I {} bash -c '
        count=$(grep -F -h "$1 " "$2" 2>/dev/null | tr -cd "1" | wc -c)
        echo "$count $1"
    ' _ {} "$att_file" | sort -rn | sed 's/^\([0-9]*\) \(.*\)/\2 \1 посещений/'
}