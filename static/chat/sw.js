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
        body: message,
        tag: 'chat',
        icon: '/static/cat.png'
    };

    if (self.registration && self.registration.showNotification) {
        // Yay, persistent notifications are supported. This SW will be woken up
        // and receive a notificationclick event when it is clicked.
        return self.registration.showNotification(title, options);
    } else if (self.Notification) {
        // HACK for very old versions of Chrome, where, only legacy non-
        // persistent notifications are supported. The click event will only be
        // received if the SW happens to stay alive. And we probably won't be
        // allowed to focus/open a tab from it.
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
    if (!clients.matchAll) // HACK for Chrome versions pre crbug.com/451334
        clients.matchAll = clients.getAll;
    // Enumerate windows, and call window.focus(), or open a new one.
    return clients.getAll({
        type: "window",
        includeUncontrolled: true
    }).catch(function(ex) {
        // Chrome doesn't yet support includeUncontrolled:true crbug.com/455241
        if (ex.name != "NotSupportedError")
            throw ex;
        return clients.getAll({
            type: "window",
            includeUncontrolled: false
        });
    }).then(function(clientList) {
        for (var i = 0; i < clientList.length; i++) {
            var client = clientList[i];
            // TODO: Intelligently choose which client to focus.
            if (client.focus)
                return client.focus();
        }
        if (clients.openWindow)
            return clients.openWindow("/chat/");
    });
}

console.log('Logged from inside SW');
