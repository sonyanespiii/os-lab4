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

    cat "$group_file" | xargs -I {} bash -c '
        name="$1"
        surname=$(echo "$name" | sed -E "s/^([A-Za-zА-Яа-яЁё]+(-[A-Za-zА-Яа-яЁё]+)*).*/\1/")
        len=${#surname}
        echo "$len $name $surname"
    ' _ {} | sort -rn | head -1 | sed -E 's/^([0-9]+) (.+) (.+)$/Студент: \2\nФамилия: \3 (длина: \1 символов)/'
}