#!/bin/bash
# src/surname.sh

get_max_surname() {
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
  
  local result
  result=$(tr -d '\r' < "$group_file" | \
    grep -v '^$' | \
    xargs -I {} sh -c '
      surname=$(echo "{}" | grep -oE "^[A-ZА-ЯЁ][a-zа-яё]*(-[A-ZА-ЯЁ][a-zа-яё]*)*")
      if [ -z "$surname" ]; then surname="{}"; fi
      len=$(printf "%s" "$surname" | wc -c | tr -d " ")
      printf "%s\t%s\t%s\n" "$len" "{}" "$surname"
    ' | \
    sort -t$'\t' -k1,1rn | \
    head -1)

  if [[ -n "$result" ]]; then
    local len=$(printf "%s" "$result" | cut -f1)
    local original=$(printf "%s" "$result" | cut -f2)
    local surname=$(printf "%s" "$result" | cut -f3)
    echo "Студент: $original"
    echo "Фамилия: $surname (длина: $len символов)"
  else
    echo "Ошибка: не удалось определить студента." >&2
    return 1
  fi
}