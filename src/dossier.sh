#!/bin/bash
# src/dossier.sh

get_dossier() {
    local student=$1
    echo "=== ДОСЬЕ СТУДЕНТА: $student ==="

    echo -e "\n[Характеристика]"
    local note
    note=$(grep -A 1 "^${student}$" data/students/general/notes/LNames.log 2>/dev/null | tail -n 1 | sed '/^--$/d')
    if [[ -n "$note" ]]; then echo "$note"; else echo "Отсутствует."; fi

    echo -e "\n[Пропуски]"
    local seq
    seq=$(grep -h "^${student} " data/*/*-attendance 2>/dev/null | cut -d' ' -f2 | tr -d '\n')
    
    if [[ -n "$seq" ]]; then
        echo "$seq" | sed 's/1/ /g' | grep -n '0' | cut -d':' -f1 | paste -sd, - | sed 's/^/Номера пропущенных занятий: /'
    else
        echo "Пропусков не зафиксировано."
    fi

    echo -e "\n[Успеваемость]"
    local grades
    grades=$(grep -h "^[^;]*;${student};" data/*/tests/TEST-* 2>/dev/null | cut -d';' -f5 | tr -d '+-')

    if [[ -n "$grades" ]]; then
        local sum count avg
        sum=$(echo "$grades" | paste -sd+ - | bc)
        count=$(echo "$grades" | wc -l | tr -d ' ')
        avg=$(echo "scale=2; $sum / $count" | bc)
        echo "Средний балл: $avg (всего оценок: $count, сумма: $sum)"
    else
        echo "Средний балл: нет данных"
    fi

    echo -e "\n[Задолженности]"
    local debts
    debts=$(grep -H "^[^;]*;${student};" data/*/tests/TEST-* 2>/dev/null | grep -E ";[12][+-]*$" | cut -d':' -f1 | cut -d'/' -f2 | sort -u | paste -sd, -)
    
    if [[ -n "$debts" ]]; then
        echo "Предметы с задолженностями: $debts"
    else
        echo "Задолженности: нет"
    fi
}