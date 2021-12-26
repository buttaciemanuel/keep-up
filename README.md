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
		    (recurrence.year = date.year or recurrence.year = '*' ) and 
		    (recurrence.month = date.month or recurrence.month = '*' ) and 
		    (recurrence.day = date.day or recurrence.weekday = '*' or recurrence.day = date.weekday or recurrence.weekday = '*' ) and
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
set recurrence.description = new_description
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

insert into recurrence(event_id, description, interval, start_time, end_time, weekday, day, month, year, id) values(
    event_id,
    new_description,
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
