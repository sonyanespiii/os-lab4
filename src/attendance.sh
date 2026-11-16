#!/bin/bash
# src/attendance.sh

get_attendance() {
  local group=$1
  local group_file="data/students/groups/${group}"

  if [[ ! -f "$group_file" ]]; then
    echo "Ошибка: список группы '$group' не найден." >&2
    return 1
  fi

  local att_files=(data/*/"${group}-attendance")

  if [[ ! -e "${att_files[0]}" ]]; then
    echo "Ошибка: файлы посещаемости для группы '$group' не найдены." >&2
    return 1
  fi

  cat "$group_file" | while read student; do
    [[ -z "$student" ]] && continue
    
    local count
    count=$(cat "${att_files[@]}" 2>/dev/null | grep "^${student} " | tr -cd '1' | wc -c)
    
    echo "$count $student"
  done | sort -rn | while read count student; do
    echo "$student $count посещений"
  done
}