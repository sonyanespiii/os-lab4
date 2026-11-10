#!/usr/bin/env bash
cd "$(dirname "$0")/.." || exit 1
R="report.txt"; : > "$R"; P=0; F=0
t(){ echo "$1" | tee -a "$R"; [ "$2" = "ok" ] && P=$((P+1)) || F=$((F+1)); }

./main.sh --help 2>&1 | grep -qi "group" && t "--help: справка" "ok" || t "--help: нет справки" "fail"
./main.sh 2>&1 | grep -q "Ошибка\|Использование" && t "без аргументов: ошибка" "ok" || t "без аргументов: нет ошибки" "fail"
./main.sh --group A-06-04 2>&1 | grep -q "Ошибка" && t "неполные аргументы: ошибка" "ok" || t "неполные: нет ошибки" "fail"

for g in A-06-04 A-09-23; do
  f="data/students/groups/$g"
  [ -f "$f" ] || { t "$g: файл не найден" "fail"; continue; }

  o=$(./main.sh --group "$g" --max-surname 2>&1)
  s=$(echo "$o" | sed -n 's/^Студент: //p' | head -1)
  l=$(echo "$o" | grep -o 'длина: [0-9]*' | grep -o '[0-9]*' | head -1)
  if grep -qx "$s" "$f" && [ -n "$l" ]; then
    al=$(printf %s "$s" | tr -d '\r' | wc -m | tr -d ' ')
    ml=0; while read -r x; do tl=$(printf %s "$x" | tr -d '\r' | wc -m | tr -d ' '); [ "$tl" -gt "$ml" ] && ml=$tl; done < "$f"
    [ "$l" = "$al" ] && [ "$l" = "$ml" ] && t "$g max-surname: $s ($l)" "ok" || t "$g max-surname: длина $l != максимум $ml" "fail"
  else t "$g max-surname: студент не из группы" "fail"; fi

  o=$(./main.sh --group "$g" --sort attendance 2>&1)
  d=$(echo "$o" | awk '{print $1}' | sort | uniq -d | head -1)
  [ -z "$d" ] && t "$g attendance: нет дубликатов" "ok" || t "$g attendance: дубликат $d" "fail"
  z=0; while read -r n; do
    ones=$(grep -h "^${n} " data/*/*-attendance 2>/dev/null | tr -cd '1' | wc -c | tr -d ' ')
    [ "$ones" -gt 0 ] && { num=$(echo "$o" | grep -m1 "^${n} " | awk '{print $2}'); [ "${num:-0}" -eq 0 ] && z=1; }
  done < "$f"
  [ "$z" -eq 0 ] && t "$g attendance: счётчики ненулевые" "ok" || t "$g attendance: нули (регрессия)" "fail"

  n=""; while read -r c; do grep -hq ";${c};" data/*/tests/TEST-* 2>/dev/null && { n=$c; break; }; done < "$f"
  [ -z "$n" ] && n=$(head -1 "$f")
  o=$(./main.sh --student "$n" --dossier 2>&1)
  lt=${n:0:1}; nf="data/students/general/notes/${lt}Names.log"
  ch=$(echo "$o" | sed -n '/\[Характеристика\]/{n;p}')
  if grep -qx "$n" "$nf" 2>/dev/null; then
    case "$ch" in *"log-"*|data/*) t "$n dossier: префикс файла" "fail" ;; "Отсутствует.") t "$n dossier: нет характеристики" "fail" ;; *) t "$n dossier: характеристика чистая" "ok" ;; esac
  else [ "$ch" = "Отсутствует." ] && t "$n dossier: нет характеристики -> 'Отсутствует.'" "ok" || t "$n dossier: странная характеристика" "fail"; fi

  ml=0; z=0; for af in data/*/*-attendance; do
    s=$(grep -h "^${n} " "$af" 2>/dev/null | head -1 | cut -d' ' -f2); [ -z "$s" ] && continue
    [ "${#s}" -gt "$ml" ] && ml=${#s}; echo "$s" | grep -q '0' && z=1
  done
  nums=$(echo "$o" | sed -n 's/^Номера пропущенных занятий: //p' | head -1)
  if [ "$z" -eq 1 ]; then
    ov=0; [ -z "$nums" ] && ov=1; IFS=',' read -ra ar <<< "$nums"
    for x in "${ar[@]}"; do [ "$x" -gt "$ml" ] 2>/dev/null && ov=1; done
    [ "$ov" -eq 0 ] && t "$n dossier: пропуски <= $ml" "ok" || t "$n dossier: пропуски > $ml (склейка)" "fail"
  else echo "$o" | grep -q "Пропусков не зафиксировано" && t "$n dossier: нет пропусков -> сообщение" "ok" || t "$n dossier: нет пропусков, нет сообщения" "fail"; fi

  grep -hq ";${n};" data/*/tests/TEST-* 2>/dev/null && {
    echo "$o" | grep "Средний балл:" | grep -q "[0-9]" && t "$n dossier: средний балл посчитан" "ok" || t "$n dossier: TEST есть, балл 'нет данных'" "fail"
  }
done

echo "-----" | tee -a "$R"; echo "PASS=$P FAIL=$F" | tee -a "$R"
[ "$F" -eq 0 ] && exit 0 || exit 1
