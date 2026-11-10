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

  local max_len=0
  local max_student=""
  local max_surname=""

  while IFS= read -r student || [[ -n "$student" ]]; do
    student="${student//$'\r'/}"
    [[ -z "$student" ]] && continue

    # Отрезаем ВСЕ заглавные буквы с конца строки (инициалы)
    # Регулярка: захватываем всё до последней строчной буквы включительно,
    # затем отрезаем все заглавные буквы до конца строки
    local surname
    surname=$(echo "$student" | sed -E 's/(.*[a-zа-яё])[A-ZА-ЯЁ]+$/\1/')
    
    # Если регулярка не сработала (нет заглавных в конце), оставляем строку как есть
    if [[ "$surname" == "$student" ]]; then
        surname="$student"
    fi

    local len=${#surname}
    
    if (( len > max_len )); then
      max_len=$len
      max_student=$student
      max_surname=$surname
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