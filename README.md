# os-lab4

## Использование

### Справка

**Вывод списка всех доступных команд:**  
`./main.sh --help`  

### Работа с группой
**Вывод списка группы, отсортированного по посещаемости (по убыванию):**  

`./main.sh --group <ID_ГРУППЫ> --sort attendance`  
*Пример:* `./main.sh --group A-09-23 --sort attendance`

**Вывод студента с максимальной длиной фамилии:**    

`./main.sh --group <ID_ГРУППЫ> --max-surname`  
*Пример:* `./main.sh --group A-09-23 --max-surname`

### Работа со студентом

**Формирование полного досье студента:**  

`./main.sh --student <ФИО> --dossier`  
*Пример:* `./main.sh --student LitvichenkoYD --dossier` 