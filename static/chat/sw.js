"use strict";

importScripts("/static/localforage.js");

if (!self.clients.getAll && self.clients.getServiced)
    self.clients.getAll = self.clients.getServiced; // Hack for backcompat.

var baseUrl = new URL("/", this.location.href) + "";

this.addEventListener("install", function(evt) {
    console.log("SW oninstall");
});

this.addEventListener("activate", function(evt) {
    console.log("SW onactivate");
});

this.addEventListener('push', function(evt) {
    // TODO: Use event.waitUntil to indicate when event handling is complete.
    console.log("SW onpush", evt.data);
    var usernameAndMessage = evt.data;
    if (typeof usernameAndMessage == "object")
        usernameAndMessage = usernameAndMessage.text();

    // Store incoming message (clients will read this on load and by polling).
    var messageSaved = localforage.getItem('messages').then(function(text) {
        var newText = (text == null ? "" : text + "\n") + usernameAndMessage;
        return localforage.setItem('messages', newText);
    });

    var notificationShown = getClientCount().then(function(count) {
        // TODO: Better UX if ||true is removed, but this makes testing easier.
        if (count == 0 || true)
            return showNotification(usernameAndMessage);
    });

    event.waitUntil(Promise.all([messageSaved, notificationShown]));
});

function getClientCount() {
    return self.clients.getAll().then(function(clientList) {
        // Only show notification when tab is closed.
        // TODO: Should also show notification when tab is open but not visible.
        return clientList.length;
    });
}

function showNotification(usernameAndMessage) {
    var splits = usernameAndMessage.split(/: (.*)/);
    var username = splits[0];
    var message = splits[1];

    var title = "Chat from " + username;
    var options = {
        serviceWorker: true, // Legacy, this has been removed from the spec.
        body: message,
        tag: 'chat',
        icon: '/static/cat.png'
    };

    if (self.registration && self.registration.showNotification) {
        // Yay, persistent notifications are supported. This SW will be woken up
        // and receive a notificationclick event when it is clicked.
        return self.registration.showNotification(title, options);
    } else if (self.Notification) {
        // Boo, only legacy non-persistent notifications are supported. The
        // click event will only be received if the SW happens to stay alive.
        // TODO: Try postMessage to client and have it show a persistent notf.
        return showLegacyNonPersistentNotification(title, options);
    }
}

function showLegacyNonPersistentNotification(title, options) {
    return new Promise(function(resolve, reject) {
        try {
            var notification = new Notification(title, options);
        } catch (ex) {
            reject(ex);
            return;
        }
        notification.onerror = reject;
        notification.onshow = function() { resolve(notification); };
        notification.onclick = onLegacyNonPersistentNotificationClick;
    });
}

this.addEventListener('notificationclick', function(evt) {
    console.log("SW notificationclick");
    handleNotificationClick(evt);
});

function onLegacyNonPersistentNotificationClick(evt) {
    console.log("SW non-persistent notification onclick");
    evt.notification = evt.notification || evt.target;
    handleNotificationClick(evt);
}

function handleNotificationClick(evt) {
    evt.notification.close();
    // Enumerate windows, and call window.focus(), or open a new one.
    self.clients.getAll().then(function(clientList) {
        for (var i = 0; i < clientList.length; i++) {
            var client = clientList[i];
            // TODO: Do a better check that the client is suitable.
            if (client.focus) {
                client.focus();
                return;
            }
        }
        // TODO: Open a new window.
    });
}

console.log('Logged from inside SW');
