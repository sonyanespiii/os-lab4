#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

TESTS_DIR="tests"
PASS_COUNT=0
FAIL_COUNT=0

echo "========================================"
echo "          ЗАПУСК ТЕСТИРОВАНИЯ           "
echo "========================================"

if [[ ! -d "$TESTS_DIR" ]]; then
    echo "Ошибка: директория '$TESTS_DIR' не найдена в корне проекта."
    echo "Создайте папку 'tests' и добавьте в неё файлы с тестами."
    exit 1
fi

shopt -s nullglob
test_files=("$TESTS_DIR"/*)
shopt -u nullglob

if [[ ${#test_files[@]} -eq 0 ]]; then
    echo "Ошибка: в директории '$TESTS_DIR' не найдено ни одного файла тестов."
    exit 1
fi

for test_file in "${test_files[@]}"; do
    [[ -f "$test_file" ]] || continue
    
    test_name=$(basename "$test_file")
    echo -e "\n[Тест] $test_name"
    
    command_line=""
    expected_output=""
    in_expected=0
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line//$'\r'/}"
        
        if [[ "$line" =~ ^COMMAND:\ *(.*) ]]; then
            command_line="${BASH_REMATCH[1]}"
            in_expected=0
        elif [[ "$line" == "EXPECT:" ]]; then
            in_expected=1
        elif [[ $in_expected -eq 1 ]]; then
            if [[ -z "$expected_output" ]]; then
                expected_output="$line"
            else
                expected_output="${expected_output}"$'\n'"${line}"
            fi
        fi
    done < "$test_file"
    
    if [[ -z "$command_line" ]]; then
        echo " ПРОПУЩЕН: не найдена строка 'COMMAND:'"
        continue
    fi
    
    actual_output=$(bash -c "$command_line" 2>&1)
    
    if [[ "$actual_output" == "$expected_output" ]]; then
        echo " PASS"
        ((PASS_COUNT++))
    else
        echo "  FAIL"
        echo "  --- Ожидаемый вывод ---"
        echo "$expected_output"
        echo "  --- Фактический вывод ---"
        echo "$actual_output"
        echo "  -----------------------"
        ((FAIL_COUNT++))
    fi
done

echo -e "\n========================================"
echo "                 ИТОГИ                    "
echo "========================================"
echo "Пройдено (PASS): $PASS_COUNT"
echo "Провалено (FAIL): $FAIL_COUNT"

if [[ $FAIL_COUNT -eq 0 ]]; then
    echo "Все тесты пройдены успешно!"
    exit 0
else
    echo "Некоторые тесты не пройдены."
    exit 1
fi