#!/usr/bin/env bash
# Регрессионный набор тестов os-lab4. Read-only по data/.
cd "$(dirname "$0")/.." || exit 1
REPORT="report.txt"; : > "$REPORT"
PASS=0; FAIL=0
log(){ echo "$@" | tee -a "$REPORT"; }
ok(){ PASS=$((PASS+1)); log "[PASS] $1"; }
bad(){ FAIL=$((FAIL+1)); log "[FAIL] $1"; }
GROUPS="A-06-04 A-09-23"

# --- 1. Аргументы ---
./main.sh --help 2>&1 | grep -qi "group" && ok "--help печатает справку" || bad "--help не печатает справку"
./main.sh 2>&1 | grep -q "Ошибка\|Использование" && ok "без аргументов -> ошибка/справка" || bad "без аргументов нет реакции"
./main.sh --group A-06-04 2>&1 | grep -q "Ошибка" && ok "неполные аргументы -> ошибка" || bad "неполные аргументы без ошибки"

for g in $GROUPS; do
  gf="data/students/groups/$g"
  [ -f "$gf" ] || { bad "группа $g: файл не найден"; continue; }

  # --- 2. max-surname ---
  out=$(./main.sh --group "$g" --max-surname 2>&1)
  stu=$(echo "$out" | sed -n 's/^Студент: //p' | head -1)
  len=$(echo "$out" | grep -o 'длина: [0-9]*' | grep -o '[0-9]*' | head -1)
  if grep -qx "$stu" "$gf" && [ -n "$len" ]; then
    alen=$(printf %s "$stu" | wc -m | tr -d ' ')
    maxlen=0
    while read -r t; do
      tl=$(printf %s "$t" | wc -m | tr -d ' '); [ "$tl" -gt "$maxlen" ] && maxlen=$tl
    done < "$gf"
    if [ "$len" = "$alen" ] && [ "$len" = "$maxlen" ]; then ok "$g --max-surname: $stu ($len)";
    else bad "$g --max-surname: длина/максимум не совпадают (вывел $len, максимум $maxlen)"; fi
  else bad "$g --max-surname: студент не из группы или нет длины"; fi

  # --- 3. sort attendance ---
  out=$(./main.sh --group "$g" --sort attendance 2>&1)
  dup=$(echo "$out" | awk '{print $1}' | sort | uniq -d | head -1)
  [ -n "$dup" ] && bad "$g attendance: дубликат строки $dup" || ok "$g attendance: дубликатов нет"
  zb=0
  while read -r n; do
    ones=$(grep -h "^${n} " data/*/*-attendance 2>/dev/null | tr -cd '1' | wc -c | tr -d ' ')
    if [ "$ones" -gt 0 ]; then
      num=$(echo "$out" | grep -m1 "^${n} " | awk '{print $2}')
      [ "${num:-0}" -eq 0 ] && zb=1
    fi
  done < "$gf"
  [ "$zb" -eq 0 ] && ok "$g attendance: счётчики ненулевые" || bad "$g attendance: нули при единицах в журнале (регрессия)"

  # --- 4. dossier ---
  n=""; while read -r c; do
    grep -hq ";${c};" data/*/tests/TEST-* 2>/dev/null && { n=$c; break; }
  done < "$gf"; [ -z "$n" ] && n=$(head -1 "$gf")
  out=$(./main.sh --student "$n" --dossier 2>&1)

  # 4a. Характеристика
  letter=${n:0:1}; nf="data/students/general/notes/${letter}Names.log"
  ch=$(echo "$out" | sed -n '/\[Характеристика\]/{n;p}')
  if grep -qx "$n" "$nf" 2>/dev/null; then
    case "$ch" in
      *"log-"*|data/*) bad "$n dossier: характеристика с префиксом файла" ;;
      "Отсутствует.")  bad "$n dossier: характеристика есть в ${letter}Names.log, выведено 'Отсутствует.'" ;;
      *) ok "$n dossier: характеристика чистая" ;;
    esac
  else
    [ "$ch" = "Отсутствует." ] && ok "$n dossier: нет характеристики -> 'Отсутствует.'" || bad "$n dossier: странная строка характеристики"
  fi

  # 4b. Пропуски
  maxl=0; zeros=0
  for f in data/*/*-attendance; do
    s=$(grep -h "^${n} " "$f" 2>/dev/null | head -1 | cut -d' ' -f2); [ -z "$s" ] && continue
    l=${#s}; [ "$l" -gt "$maxl" ] && maxl=$l
    echo "$s" | grep -q '0' && zeros=1
  done
  nums=$(echo "$out" | sed -n 's/^Номера пропущенных занятий: //p' | head -1)
  if [ "$zeros" -eq 1 ]; then
    over=0; [ -z "$nums" ] && over=1
    IFS=',' read -ra arr <<< "$nums"
    for x in "${arr[@]}"; do [ "$x" -gt "$maxl" ] 2>/dev/null && over=1; done
    [ "$over" -eq 0 ] && ok "$n dossier: номера пропусков <= $maxl" || bad "$n dossier: номера пропусков > $maxl (склейка предметов)"
  else
    echo "$out" | grep -q "Пропусков не зафиксировано" && ok "$n dossier: нет пропусков -> сообщение" || bad "$n dossier: нет пропусков, но сообщения нет"
  fi

  # 4c. Успеваемость
  if grep -hq ";${n};" data/*/tests/TEST-* 2>/dev/null; then
    echo "$out" | grep "Средний балл:" | grep -q "[0-9]" && ok "$n dossier: средний балл посчитан" || bad "$n dossier: записи TEST есть, но 'Средний балл: нет данных'"
  fi
done

log "-----"; log "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
