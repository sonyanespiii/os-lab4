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

  tr -d '\r' < "$group_file" | sort -u | grep -v '^$' | \
  xargs -I{} sh -c '
    name="{}"
    count=$(grep -E "^${name} " "$1" 2>/dev/null | tr -cd "1" | wc -c)
    printf "%d\t%s\n" "$count" "$name"
  ' _ "$att_file" | \
  sort -rn -k1,1 | \
  sed -E 's/^([0-9]+)[[:space:]]+(.+)$/\2 \1 посещений/'
}