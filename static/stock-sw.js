this.addEventListener("install", function(evt) {
    console.log("SW oninstall");
});

this.addEventListener("activate", function(evt) {
    console.log("SW onactivate");
});

this.addEventListener('push', function(evt) {
    console.log("SW onpush \"" + evt.data + "\"");
    var mayData = JSON.parse(evt.data);

    var notification = new Notification("Stock price dropped", {
        serviceWorker: true,
        body: "FOOBAR dropped from $1030 to $" + mayData[1],
        tag: 'stock',
        icon: 'http://www.courtneyheard.com/wp-content/uploads/2012/10/chart-icon.png'
    });
    console.log(notification);
}, false);

this.addEventListener('notificationclick', function(evt) {
    // TODO: notification.close();
    console.log("SW notificationclick");
    // TODO: Enumerate windows, and call window.focus(), or open a new one.
    // TODO: drawChart(mayData) in the focused/opened tab.
});

console.log('Logged from inside SW');