#!/bin/bash
# src/surname.sh

get_max_surname() {
  local group=$1
  local group_file="data/students/groups/${group}"

  if [[ ! -s "$group_file" ]]; then
    echo "Ошибка: список группы '$group' не найден." >&2
    return 1
  fi

  local max_len=0
  local max_student=""
  local max_surname=""

  while read student || [[ -n "$student" ]]; do
    [[ -z "$student" ]] && continue

    local surname
    surname=$(grep -oE '^[A-ZА-ЯЁ][a-zа-яё]*(-[A-ZА-ЯЁ][a-zа-яё]*)*' <<< "$student")
    
    if [[ -z "$surname" ]]; then
      surname="$student"
    fi

    local len=${#surname}
    
    if (( len > max_len )); then
      max_len=$len
      max_student="$student"
      max_surname="$surname"
    fi
  done < "$group_file"

  if [[ -n "$max_student" ]]; then
    echo "Студент: $max_student"
    echo "Фамилия: $max_surname (длина: $max_len символов)"
  else
    echo "Ошибка: не удалось определить студента." >&2
    return 1
  fi
}