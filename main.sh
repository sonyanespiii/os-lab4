#!/bin/bash
# main.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/src/attendance.sh"
source "${SCRIPT_DIR}/src/surname.sh"
source "${SCRIPT_DIR}/src/dossier.sh"

if [[ $# -eq 0 ]]; then
    echo "Ошибка: не указаны аргументы. Используйте --help для справки." >&2
    exit 1
fi

case "$1" in
    --group)
        if [[ -z "$2" || -z "$3" ]]; then
            echo "Ошибка: неполные аргументы для --group." >&2
            exit 1
        fi
        GROUP=$2
        case "$3" in
            --sort)
                if [[ "$4" == "attendance" ]]; then
                    get_attendance "$GROUP"
                else
                    echo "Ошибка: поддерживается только сортировка 'attendance'." >&2
                    exit 1
                fi
                ;;
            --max-surname)
                get_max_surname "$GROUP"
                ;;
            *)
                echo "Ошибка: неизвестная операция '$3' для группы." >&2
                exit 1
                ;;
        esac
        ;;
    --student)
        if [[ -z "$2" || -z "$3" ]]; then
            echo "Ошибка: неполные аргументы для --student." >&2
            exit 1
        fi
        STUDENT=$2
        if [[ "$3" == "--dossier" ]]; then
            get_dossier "$STUDENT"
        else
            echo "Ошибка: для студента доступна только опция '--dossier'." >&2
            exit 1
        fi
        ;;
    --help)
        echo "Использование:"
        echo "  ./main.sh --group <GROUP_ID> --sort attendance"
        echo "  ./main.sh --group <GROUP_ID> --max-surname"
        echo "  ./main.sh --student <FULL_NAME> --dossier"
        echo ""
        echo "Примеры:"
        echo "  ./main.sh --group A-09-23 --sort attendance"
        echo "  ./main.sh --student LitvichenkoYD --dossier"
        ;;
    *)
        echo "Ошибка: неизвестный аргумент '$1'. Используйте --help." >&2
        exit 1
        ;;
esac