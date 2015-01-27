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
    var messagesUrl = "https://johnme-gcm.appspot.com/chat/messages";
    evt.waitUntil(fetch(messagesUrl).then(function(response) {
        return response.text();
    }).then(function(messages) {
        console.log("SW onpush", messages);

        var usernameAndMessage = messages.split('\n').pop();

        var messageIsBlank = /^[^:]*: $/.test(usernameAndMessage);
        if (messageIsBlank)
            messages += "<empty message, so no notification shown>"

        // Store incoming messages (clients will read this by polling).
        var savePromise = localforage.setItem('messages', messages);

        if (messageIsBlank)
            return savePromise;

        // TODO: Don't show notification if chat tab is open and visible.
        var notifyPromise = showNotification(usernameAndMessage);

        return Promise.all([savePromise, notifyPromise]);
    }));    
});

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
            // Either Notification is not exposed to SW, or is not
            // constructible, or we lost permission.
            reject(ex);
            return;
        }
        notification.onerror = reject;
        // TODO: onshow has been removed from the spec; probably better to
        // assume it will succeed if Notification.permission == "granted"
        notification.onshow = function() { resolve(notification); };
        notification.onclick = onLegacyNonPersistentNotificationClick;
    });
}

this.addEventListener('notificationclick', function(evt) {
    console.log("SW notificationclick");
    evt.waitUntil(handleNotificationClick(evt));
});

function onLegacyNonPersistentNotificationClick(evt) {
    console.log("SW non-persistent notification onclick");
    evt.notification = evt.notification || evt.target;
    handleNotificationClick(evt);
}

function handleNotificationClick(evt) {
    evt.notification.close();
    // Enumerate windows, and call window.focus(), or open a new one.
    return self.clients.getAll().then(function(clientList) {
        for (var i = 0; i < clientList.length; i++) {
            var client = clientList[i];
            // TODO: Do a better check that the client is suitable.
            if (client.focus) {
                return client.focus();
            }
        }
        // TODO: Open a new window.
    });
}

console.log('Logged from inside SW');
