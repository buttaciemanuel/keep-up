const CronJob = require('cron').CronJob;

// pulisce il database da eventi privi di ricorrenze
const job = new CronJob('0 * * * *', function () {
    const eventQuery = new Parse.Query("Event").fromLocalDatastore();

    eventQuery.find({ useMasterKey: true }).then(events => {
        events.forEach(event => {
            let recurrenceQuery = new Parse.Query("Recurrence").fromLocalDatastore();

            recurrenceQuery.equalTo("eventId", {
                __type: 'Pointer',
                className: 'Event',
                objectId: event.id
            });
            
            recurrenceQuery.find({ useMasterKey: true }).then(recurrences => {
                // no ricorrenze individuate
                if (recurrences.length == 0) {
                    console.log('deleting event ', event.get('title'));
                    // rimuove le eccezioni
                    let removeExceptionQuery = new Parse.Query("Exception").fromLocalDatastore();

                    removeExceptionQuery.equalTo("eventId", {
                        __type: 'Pointer',
                        className: 'Event',
                        objectId: event.id
                    });

                    removeExceptionQuery.find({ useMasterKey: true }).then(exceptions => {
                        for (var i = 0; i < exceptions.length; ++i) exceptions[i].destroy({ useMasterKey: true });
                    });
                    // rimuove il goal associato
                    let removeGoalQuery = new Parse.Query("Goal").fromLocalDatastore();

                    removeGoalQuery.equalTo("eventId", {
                        __type: 'Pointer',
                        className: 'Event',
                        objectId: event.id
                    });

                    removeGoalQuery.find({ useMasterKey: true }).then(goals => {
                        for (var i = 0; i < goals.length; ++i) goals[i].destroy({ useMasterKey: true });
                    });
                    // rimuove l'evento
                    event.destroy({ useMasterKey: true });
                }
            }).catch(error => {
                console.log('error: ', error);
            });
        });
    }).catch(error => {
        console.log('error: ', error);
    });
}, null, true, 'Europe/Rome');

job.start();

Parse.Cloud.job("myJob", async (request) => {
    return "Yes, bitch";
});

Parse.Cloud.define("hello", (request) => {
    return `You sent ${request.params.movie}`;
});