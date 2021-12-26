Parse.Cloud.define("hello", (request) => {
    return `You sent ${request.params.movie}`;
});