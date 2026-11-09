#!/bin/bash
# src/dossier.sh

get_dossier() {
    local student=$1
    
    if [[ ! "$student" =~ ^[A-Za-zА-Яа-яЁё0-9\-]+$ ]]; then
        echo "Ошибка: некорректный формат имени студента." >&2
        return 1
    fi

    echo "=== ДОСЬЕ СТУДЕНТА: $student ==="

    echo -e "\n[Характеристика]"
    local note
    note=$(grep -A 1 "^${student}$" data/students/general/notes/*Names.log 2>/dev/null | tail -n 1 | sed '/^--$/d')
    if [[ -n "$note" ]]; then 
        echo "$note"
    else 
        echo "Отсутствует."
    fi

    echo -e "\n[Пропуски]"
    local seq
    seq=$(grep -F -h "$student " data/*/*-attendance 2>/dev/null | cut -d' ' -f2 | tr -d '\n')
    
    if [[ -n "$seq" ]]; then
        local missed
        missed=$(echo "$seq" | sed 's/./&\n/g' | grep -n '0' | cut -d':' -f1 | paste -sd, -)
        
        if [[ -n "$missed" ]]; then
            echo "Номера пропущенных занятий: $missed"
        else
            echo "Пропусков не зафиксировано."
        fi
    else
        echo "Пропусков не зафиксировано."
    fi

    echo -e "\n[Успеваемость]"
    local grades
    grades=$(grep -F -h ";${student};" data/*/tests/TEST-*.txt 2>/dev/null | cut -d';' -f5 | tr -d '+-')

    if [[ -n "$grades" ]]; then
        local sum_expr
        sum_expr=$(echo "$grades" | paste -sd+ -)
        local sum=$((sum_expr))
        local count=$(echo "$grades" | wc -l | tr -d ' ')
        
        local avg_int=$(( (sum * 100) / count ))
        local whole=$((avg_int / 100))
        local frac=$((avg_int % 100))
        local frac_fmt
        frac_fmt=$(printf "%02d" "$frac")
        
        echo "Средний балл: ${whole}.${frac_fmt} (всего оценок: $count, сумма: $sum)"
    else
        echo "Средний балл: нет данных"
    fi

    echo -e "\n[Задолженности]"
    local debts
    debts=$(grep -F -H ";${student};" data/*/tests/TEST-*.txt 2>/dev/null | grep -E ";[12][+-]*$" | cut -d':' -f1 | cut -d'/' -f2 | sort -u | paste -sd, -)
    
    if [[ -n "$debts" ]]; then
        echo "Предметы с задолженностями: $debts"
    else
        echo "Задолженности: нет"
    fi
}