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
  local first_char="${student:0:1}"
  local note
  note=$(grep -A 1 "^${student}$" "data/students/general/notes/${first_char}Names.log" 2>/dev/null | tail -n 1)

  if [[ -n "$note" ]]; then
    echo "$note"
  else
    echo "Отсутствует."
  fi

  echo ""
  
  echo "[Пропуски]"
  local found_absences=0
  
  for subject in "Пересдачеведение" "Цирковое_Дело"; do
    local seq
    seq=$(grep -E -h "^${student} " "data/${subject}"/*-attendance 2>/dev/null | head -n 1 | cut -d' ' -f2 | tr -d '\n\r')
    
    if [[ -n "$seq" ]]; then
      local missed=()
      local pos=1
      
      for (( i=0; i<${#seq}; i++ )); do
        if [[ "${seq:$i:1}" == "0" ]]; then
          missed+=("$pos")
        fi
        ((pos++))
      done
      
      if [[ ${#missed[@]} -gt 0 ]]; then
        echo "${subject}: ${missed[*]}"
        found_absences=1
      fi
    fi
  done
  
  if [[ $found_absences -eq 0 ]]; then
    echo "Пропусков не зафиксировано."
  fi

  echo ""
  
  echo "[Успеваемость]"
  local grades
  grades=$(grep -E -h "^[^;]+;${student};" data/*/tests/TEST-* 2>/dev/null | cut -d';' -f5 | sed 's/[+-]//g' | grep -E '^[0-9]+$')
  
  if [[ -n "$grades" ]]; then
    local sum=0
    local count=0
    
    while read -r grade; do
      sum=$((sum + grade))
      count=$((count + 1))
    done <<< "$grades"
    
    if (( count > 0 )); then
      local avg
      avg=$(awk "BEGIN {printf \"%.2f\", $sum / $count}")
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

  for subject in "Пересдачеведение" "Цирковое_Дело"; do
    local test_dir="data/${subject}/tests"
    if [[ -d "$test_dir" ]]; then
      local debts=()
      
      for test_file in "$test_dir"/TEST-*; do
        [[ -f "$test_file" ]] || continue
        
        if grep -E "^[^;]+;${student};" "$test_file" 2>/dev/null | grep -qE ";[012][+-]*$"; then
          local test_name
          test_name=$(basename "$test_file" | sed -E 's/TEST-([0-9]+)/тест №\1/')
          debts+=("$test_name")
        fi
      done
      
      if [[ ${#debts[@]} -gt 0 ]]; then
        local debts_str
        debts_str=$(printf "%s, " "${debts[@]}" | sed 's/, $//')
        echo "${subject}: $debts_str"
        found_debts=1
      fi
    fi
  done

  if [[ $found_debts -eq 0 ]]; then
    echo "Задолженности: нет"
  fi
}