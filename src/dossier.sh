#!/bin/bash
# src/dossier.sh

get_dossier() {
  local student=$1

  if [[ ! "$student" =~ ^[A-Za-zА-Яа-яЁё0-9-]+$ ]]; then
    echo "Ошибка: некорректный формат имени студента." >&2
    return 1
  fi

  echo "=== ДОСЬЕ СТУДЕНТА: $student ==="
  echo ""
  
  echo "[Характеристика]"
  local note
  note=$(sed -n "/^${student}$/{n;p;}" data/students/general/notes/*Names.log 2>/dev/null)
  if [[ -n "$note" ]]; then
    echo "$note"
  else
    echo "Отсутствует."
  fi

  echo ""
  echo "[Пропуски]"
  local seq
  seq=$(grep -E -h "^${student} " data/*/*-attendance 2>/dev/null | cut -d' ' -f2 | tr -d '\n')
  if [[ -n "$seq" ]]; then
    local missed
    missed=$(echo "$seq" | grep -bo '0' | awk -F: '{print $1+1}' | paste -sd, -)
    if [[ -n "$missed" ]]; then
      echo "Номера пропущенных занятий: $missed"
    else
      echo "Пропусков не зафиксировано."
    fi
  else
    echo "Пропусков не зафиксировано."
  fi

  echo ""
  echo "[Успеваемость]"
  local grades
  grades=$(grep -E "^[^;]+;${student};" data/*/tests/TEST-* 2>/dev/null | cut -d';' -f5 | tr -dc '0-9\n')
  if [[ -n "$grades" ]]; then
    local avg_info
    avg_info=$(echo "$grades" | awk '{sum+=$1; count++} END {if(count>0) printf "%d %d %.2f", sum, count, sum/count; else print "0 0 0"}')
    read -r sum count avg <<< "$avg_info"
    if (( count > 0 )); then
      echo "Средний балл: ${avg} (всего оценок: $count, сумма: $sum)"
    else
      echo "Средний балл: нет данных"
    fi
  else
    echo "Средний балл: нет данных"
  fi

  echo ""
  echo "[Задолженности]"
  local debts
  debts=$(grep -E -H "^[^;]+;${student};" data/*/tests/TEST-* 2>/dev/null | grep -E ";[12][+-]*$" | cut -d':' -f1 | cut -d'/' -f2 | sort -u | paste -sd, -)
  if [[ -n "$debts" ]]; then
    echo "Предметы с задолженностями: $debts"
  else
    echo "Задолженности: нет"
  fi
}