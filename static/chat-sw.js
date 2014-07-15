"use strict";

importScripts("/static/localforage.js");
importScripts("/static/polyfills/idbCacheUtils.js");
importScripts("/static/polyfills/fetchPolyfill.js");
importScripts("/static/polyfills/idbCachePolyfill.js");
importScripts("/static/polyfills/idbCacheStoragePolyfill.js");

var baseUrl = new URL("/", this.location.href) + "";

this.addEventListener("install", function(evt) {
    console.log("SW oninstall");
    evt.waitUntil(caches.create("core").then(function(core) {
        var resourceUrls = [
            'chat',
            'static/chat-sw.js',
            'static/chat.png',
            'static/hamburger.svg',
            'static/hangouts.png',
            'static/localforage.js',
            'static/roboto.css',
            'static/roboto.woff',
            'static/send.png'
        ];

        return Promise.all(resourceUrls.map(function(relativeUrl) {
            return core.add(baseUrl + relativeUrl);
        }));
    }));
});

this.addEventListener("activate", function(evt) {
    console.log("SW onactivate");
});

this.addEventListener("fetch", function(evt) {
    var request = evt.request;

    // Skip any cross-origin URLs for now.
    if (this.scope.indexOf(request.origin) == -1) {
        console.log("onfetch skipped because bad scope, for " + request.url);
        return;
    }

    evt.respondWith(
        caches.match(request, "core").then(function(response) {
            //console.log("onfetch success for " + request.url);
            return response;
        }, function(err) {
            console.log("onfetch falling back to network for " + request.url);
            console.log(request.url + ":" + err);
            return fetch(request);
        }).catch(function() {
            console.log("onfetch GOING SUPERHACK for " + request.url);
            var headers = new HeaderMap();
            headers.set('Content-Type', 'text/html');
            new Response(
                new Blob(['<meta http-equiv="refresh" content="1">']),
                {headers: headers}
            );
        })
    );
});

this.addEventListener('push', function(evt) {
    console.log("SW onpush \"" + evt.data + "\"");
    var usernameAndMessage = evt.data;

    // Store incoming message (clients will read this on load and by polling).
    localforage.getItem('messages').then(function(text) {
        var newText = (text == null ? "" : text + "\n") + usernameAndMessage;
        localforage.setItem('messages', newText);
    });

    self.clients.getServiced().then(function(clients) {
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
        icon: '/static/chat.png'
    });
}

this.addEventListener('notificationclick', function(evt) {
    // TODO: notification.close();
    console.log("SW notificationclick");
    // TODO: Enumerate windows, and call window.focus(), or open a new one.
});

console.log('Logged from inside SW');