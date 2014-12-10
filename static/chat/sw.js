"use strict";

importScripts("/static/localforage.js");

var baseUrl = new URL("/", this.location.href) + "";

this.addEventListener("install", function(evt) {
    console.log("SW oninstall");
});

this.addEventListener("activate", function(evt) {
    console.log("SW onactivate");
});

this.addEventListener('push', function(evt) {
    console.log("SW onpush", evt.data);
    var usernameAndMessage = evt.data;
    if (typeof usernameAndMessage == "object")
        usernameAndMessage = usernameAndMessage.text();

    // Store incoming message (clients will read this on load and by polling).
    localforage.getItem('messages').then(function(text) {
        var newText = (text == null ? "" : text + "\n") + usernameAndMessage;
        localforage.setItem('messages', newText);
    });

    if (!self.clients.getAll && self.clients.getServiced)
        self.clients.getAll = self.clients.getServiced; // Hack for backcompat.
    self.clients.getAll().then(function(clients) {
        // Only show notification when tab is closed.
        // TODO: Should also show notification when tab is open but not visible.
        if (clients.length == 0)
            showNotification(usernameAndMessage);
    });
});

function showNotification(usernameAndMessage) {
    var splits = usernameAndMessage.split(/: (.*)/);
    var username = splits[0];
    var message = splits[1];

    var notification = new Notification("Chat from " + username, {
        serviceWorker: true,
        body: message,
        tag: 'chat',
        icon: '/static/cat.png'
    });
}

this.addEventListener('notificationclick', function(evt) {
    // TODO: notification.close();
    console.log("SW notificationclick");
    // TODO: Enumerate windows, and call window.focus(), or open a new one.
});

console.log('Logged from inside SW');