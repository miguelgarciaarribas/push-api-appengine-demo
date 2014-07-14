"use strict";

importScripts("/static/localforage.js");

this.addEventListener("install", function(evt) {
    console.log("SW oninstall");
});

this.addEventListener("activate", function(evt) {
    console.log("SW onactivate");
});

this.addEventListener('push', function(evt) {
    console.log("SW onpush \"" + evt.data + "\"");
    var usernameAndMessage = evt.data;

    // Store incoming message (clients will read this on load and by polling).
    localforage.getItem('messages').then(function(text) {
        var newText = (text == null ? "" : text + "\n") + usernameAndMessage;
        localforage.setItem('messages', newText);
    });

    showNotification(usernameAndMessage);
});

function showNotification(usernameAndMessage) {
    var splits = usernameAndMessage.split(/: (.*)/);
    var username = splits[0];
    var message = splits[1];

    var notification = new Notification("Chat from " + username, {
        serviceWorker: true,
        body: message,
        tag: 'chat',
        icon: '/static/chat.png'
    });
}

this.addEventListener('notificationclick', function(evt) {
    // TODO: notification.close();
    console.log("SW notificationclick");
    // TODO: Enumerate windows, and call window.focus(), or open a new one.
});

console.log('Logged from inside SW');