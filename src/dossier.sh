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
  local found_absences=0
  
  local seq1
  seq1=$(grep -E -h "^${student} " data/Пересдачеведение/*-attendance 2>/dev/null | cut -d' ' -f2 | tr -d '\n')
  if [[ -n "$seq1" ]]; then
    local missed1
    missed1=$(echo "$seq1" | grep -bo '0' | cut -d: -f1 | xargs -I{} expr {} + 1 | paste -sd' ' -)
    if [[ -n "$missed1" ]]; then
      echo "Пересдачеведение: $missed1"
      found_absences=1
    fi
  fi
  
  local seq2
  seq2=$(grep -E -h "^${student} " data/Цирковое_Дело/*-attendance 2>/dev/null | cut -d' ' -f2 | tr -d '\n')
  if [[ -n "$seq2" ]]; then
    local missed2
    missed2=$(echo "$seq2" | grep -bo '0' | cut -d: -f1 | xargs -I{} expr {} + 1 | paste -sd' ' -)
    if [[ -n "$missed2" ]]; then
      echo "Цирковое_Дело: $missed2"
      found_absences=1
    fi
  fi
  
  if [[ $found_absences -eq 0 ]]; then
    echo "Пропусков не зафиксировано."
  fi

  echo ""
  
  echo "[Успеваемость]"
  local grades
  grades=$(grep -E -h "^[^;]+;${student};" data/*/tests/TEST-* 2>/dev/null | cut -d';' -f5 | grep -E '^[0-9]+$')
  if [[ -n "$grades" ]]; then
    local sum_expr
    sum_expr=$(echo "$grades" | paste -sd+ -)
    local sum
    sum=$(echo "$sum_expr" | bc)
    local count
    count=$(echo "$grades" | wc -l | tr -d ' ')
    local avg
    avg=$(echo "scale=2; $sum / $count" | bc)
    
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
  local found_debts=0
  
  local debts1
  debts1=$(grep -E -h "^[^;]+;${student};" data/Пересдачеведение/tests/TEST-* 2>/dev/null | grep -E ";[12][+-]*$" | cut -d';' -f3 | sort | paste -sd', ' -)
  if [[ -n "$debts1" ]]; then
    echo "Пересдачеведение: $debts1"
    found_debts=1
  fi
  
  local debts2
  debts2=$(grep -E -h "^[^;]+;${student};" data/Цирковое_Дело/tests/TEST-* 2>/dev/null | grep -E ";[12][+-]*$" | cut -d';' -f3 | sort | paste -sd', ' -)
  if [[ -n "$debts2" ]]; then
    echo "Цирковое_Дело: $debts2"
    found_debts=1
  fi
  
  if [[ $found_debts -eq 0 ]]; then
    echo "Задолженности: нет"
  fi
}