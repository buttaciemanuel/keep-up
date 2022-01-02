# KeepUp

L'app per diventare cazzuto.

## Implementazione degli algoritmi

Questa sezione contiene gli algoritmi per la gestione del data model all'interno del database relazionale. Ad ogni evento sono collegate delle occorrenze, che vengono definite mediante dei pattern. Questo è utile a rappresentare la ripetitività nel tempo di certi eventi cercando di ottimizzare l'utilizzo dello spazio. Inoltre è presente una tabella dedicata alle eccezioni riguardo a certi eventi, ovvero la loro cancellazione o ripianificazione.

### Ottenere gli eventi di una data

Questo algoritmo serve a elencare quali eventi sono programmati in una certa data, dato un certo utente, presente o futura.

~~~~sql
select event.name, recurrence.start_time, recurrence.end_time
from event, recurrence
where event.creator_user_id = user and event.id = recurrence.event_id and (
        (date.timestamp - event.start_date.timestamp) % recurrence.interval.timestamp = 0 or (
		    (recurrence.year = date.year or recurrence.year = '*') and 
		    (recurrence.month = date.month or recurrence.month = '*') and 
		    (recurrence.day = date.day or recurrence.weekday = '*' or recurrence.day = date.weekday or recurrence.weekday = '*') and
		    date >= event.start_date and date <= event.end_date
	    )
	) and (recurrence.event_id, recurrence.id) not in (
		select exception.event_id, exception.recurrence_id
		from exception
		where date = exception.on_date
	)
~~~~

### Riprogrammare un'intera serie di eventi

Questo significa riprogrammare ad esempio tutte le occorrenze di un certo evento con un nuovo pattern.

~~~~sql
update recurrence
set recurrence.interval = new_interval
set recurrence.day = new_day
set recurrence.month = new_month
set recurrence.year = new_year
set recurrence.weekday = new_weekday
set recurrence.start_time = new_start_time
set recurrence.end_time = new_end_time
where recurrence.event_id = event_id and recurrence.id = recurrence_id
~~~~

### Riprogrammare un evento eccezionalmente in un dato giorno

Ciò implica che solo un una certa data l'evento è ripianificato, cambiando magari il suo orario o la sua data.

~~~~sql
insert into exception(event_id, recurrence_id, is_rescheduled, is_cancelled, on_date) values(
    event_id,
    recurrence_id,
    is_rescheduled,
    is_cancelled,
    exception_date
);

insert into recurrence(event_id, interval, start_time, end_time, weekday, day, month, year, id) values(
    event_id,
    null,
    new_start_time,
    new_end_time,
    new_weekday,
    new_day,
    new_month,
    new_year,
    auto_generated_id
);
~~~~

### Algoritmo di pianificazione degli obiettivi

Per individuare un buon algoritmo che pianifichi gli obiettivi nel tempo è necessario in primis determinare una funzione di costo che descriva la bontà con cui è avvenuta una pianificazione settimanale.

~~~~
// genera i task pending dai goal
pendingTasks(goals: Goal[]) -> Task[]
    let result: Task[] = []
    for goal in goals
        for i in goal.recurrencesCount
            result.add(Task(goal.name, goal.recurrenceDuration, goal.category))
    return result

// tasks è la lista di task della giornata (sia impegni sia goal)
// il costo è meglio quanto pù è basso
cost(pending: Task[], fixed: Task[]) -> double
    // ore totali utilizzate nella giornata (goal + non-goal)
    let busyHours: int[7] = [0]
    // ore dedicate allo studio in ogni giornata (goal)
    let studyHours: int[7] = [0]
    // ore dedicate allo sport in ogni giornata (goal)
    let sportHours: int[7] = [0]
    // ore dedicate ad obiettivi (goal)
    let otherHours: int[7] = [0]
    // distanza fra i giorni associati ad ogni obiettivo, questo non deve essere mai zero
    let goalDays: map<string, set<int>> = {}
    // numero di task per ogni goal
    let goalTasksCount: map<string, int> = {}
    // conta le ore di impegni non goal
    for task in fixed
        busyHours[task.weekDay] += task.duration
    // calcola per ogni giorno quante ore di studio sono presenti (goal)
    for task in pending
        goalDays.putIfAbsent(task.title, {})
        goalDays[task.title].insert(task.weekDay)
        goalTasksCount.putIfAbsent(task.title, 0)
        ++goalTaskCount[task.title]
        busyHours[task.weekDay] += task.duration
        if task.category is EDUCATION
            studyHours[task.weekDay] += task.duration
        elif task.category is SPORT
            sportHours[task.weekDay] += task.duration
        else
            otherHours[task.weekDay] += task.duration
    // per ogni obiettivo verifica che ve ne sia una ricorrenza solo in una giornata
    for goal in goalTasksCount.keys
        if goalDays[goal] != goalTasksCount[goal]
            return inf
    // calcola la varianza associata alle varie tipologie di attività, meno è meglio
    let busyHoursVariance = variance(busyHours)
    let studyHoursVariance = variance(studyHours)
    let sportHoursVariance = variance(sportHours)
    let otherHoursVariance = variance(otherHours)
    // restituisce il risultato come prodotto di fattori di bontà, meno è meglio
    return busyHoursVariance * studyHoursVariance * sportHoursVariance * otherHoursVariance
~~~~

Ora bisogna ipotizzare un algoritmo di allocazione dei task nella settimana. Facciamo un tentativo greedy.

~~~~
// dispone i task fissi su una matrice di riempimento
// i giorni sono nell'intervallo [0, 6]
// un task non può essere per logica disposto a cavallo di due giorni
fillWeekTable(fixed: Task[], availabilityHours: (int, int))
    const n = 7 * 24
    // la cella contiene l'indice del task disposto come ore
    let table: int[n] = [-1]
    // assegna i task nella matrice
    for i in 0..fixed.length
        // l'indice di ora di inizio
        let startIndex = task[i].day * 24 + task[i].start.hour
        // l'indice di ore di fine
        let endIndex = task[i].day * 24 + task[i].end.hour
        // viene avanzato se si prende dei minuti dell'ora successiva
        if task[i].end.minute > 0
            ++endIndex
        // riempie la tabella con l'indice del task
        for j in startIndex..endIndex
            table[j] = i
    // riempie le ore notturne non utilizzate con inf
    for i in 0..7
        for j in 0..availabilityHours.first
            let k = i * 24 + j
            if table[k] < 0
                table[k] = inf
        for j in availabilityHours.last..24
            let k = i * 24 + j
            if table[k] < 0
                table[k] = inf
    return table

allocateTasks(fixed: Task[], pending: Task[], attempts: int)
    let bestCost = inf
    let best: Task[pending.length]
    // ordiniamo i task già posizionati per data di inizio
    sort(fixed)
    // crea una matrice di riempimento
    let weekTable = fillWeekTable(fixed, Time(8, 0), Time(23, 0))
    // fai un numero scelto di tentativi
    for i in 0..attempts
        // resetta gli orari
        for task in pending
            task.start = task.end = task.weekDay = null
        // arrangia random i task
        shuffle(pending)
        // numero medio di task per giorno
        let dayAverage = pending.length / 7
        // numero di task assegnati in un dato giorno
        let assigned: int[7] = [0]
        // dispone i task dei goal
        let k = 0
        // numero di task assegnati
        let count = 0
        // cerca di posizionare ogni task nella table
        for task in pending
            // giorno
            let day = floor(k / 24)
            // se la soglia giornaliera di attività è quasi satura, si procede al giorno seguente
            if assigned[day] > dayAverage + 1
                k = 24 * (1 + day)
            // finchè c'è un task, avanza
            while k < 24 * 7
                if not intersection(weekTable, task, k)
                    task.start = Time(k % 24, 0)
                    task.end = task.start + task.duration
                    k += task.duration
                    task.weekDay = floor(k / 24)
                    ++assigned[task.weekDay]
                    ++count
                    break
                do
                    ++k
                while weekTable[k] >= 0
        // se non sono stati assegnati tutti, allora salta il tentativo
        if i < attempts - 1 and count < pending.count
            continue
        // valuta la bontà della disposizione
        let cost = cost(pending, fixed)
        if cost < bestCost
            bestCost = cost
            best = pending.clone()
    // restituisce la soluzione migliore
    return best
~~~~