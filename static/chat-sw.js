this.addEventListener("install", function(evt) {
    console.log("SW oninstall");
});

this.addEventListener("activate", function(evt) {
    console.log("SW onactivate");
});

this.addEventListener('push', function(evt) {
    console.log("SW onpush \"" + evt.data + "\"");
    var usernameAndMessage = evt.data;

    var splits = usernameAndMessage.split(/: (.*)/);
    var username = splits[0];
    var message = splits[1];

    var notification = new Notification("Chat from " + username, {
        serviceWorker: true,
        body: message,
        tag: 'chat',
        icon: '/static/chat.png'
    });
    console.log(notification);
});

this.addEventListener('notificationclick', function(evt) {
    // TODO: notification.close();
    console.log("SW notificationclick");
    // TODO: Enumerate windows, and call window.focus(), or open a new one.
    // TODO: $('#incoming-messages').textContent += "\n" + usernameAndMessage;
    //       in the focused/opened tab.
});

console.log('Logged from inside SW');