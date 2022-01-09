const CronJob = require('cron').CronJob;

var job = new CronJob('00 11 23 * * *', function () {
    console.log("executing");
    // per ogni evento privo di ricorrenze, elimina l'evento
    let query = new Parse.Query("Event");
    query.find({ useMasterKey: true,
            success: function (events) {
                console.log("success");
                events.forEach(event => {
                    console.log(event.title);
                    let recurrencesQuery = new Parse.Query("Recurrence");
                    recurrencesQuery.equalTo("eventId", {
                        __type: 'Pointer',
                        className: 'Event',
                        objectId: event.id
                    });
                    recurrencesQuery.find({ useMasterKey: true,
                            success: function (recurrences) {
                                console.log(recurrences);
                                if (recurrences.length == 0) {
                                    console.log("deleting " + event.title);
                                    event.destroy();
                                }
                            },
                            error: function (error) { }
                        });
                });
            },
            error: function (error) { console.log(error); }
        }
    );
}, null, true, 'Europe/Rome');

job.start();

Parse.Cloud.job("myJob", async (request) => {
    return "Yes, bitch";
});

Parse.Cloud.define("hello", (request) => {
    return `You sent ${request.params.movie}`;
});