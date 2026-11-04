#!/bin/bash
# src/surname.sh

get_max_surname() {
    local group=$1
    local group_file="data/students/groups/${group}"
    
    if [[ ! -f "$group_file" ]]; then
        echo "Ошибка: список группы '$group' не найден." >&2
        return 1
    fi

    sed -E 's/^([A-Z][a-z]+).*/\1/' "$group_file" | xargs -I {} sh -c '
        len=$(echo -n "{}" | wc -c | tr -d " ")
        echo "$len {}"
    ' | sort -rn | head -1 | sed 's/^\([0-9]*\) \(.*\)/Студент: \2\nФамилия: \2 (длина: \1 символов)/'
}