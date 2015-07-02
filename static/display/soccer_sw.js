"use strict";

importScripts("/static/localstore/soccer_db.js");
importScripts("/static/localstore/soccer_access.js");

var CACHE_NAME = 'my-site-cache-v1';
var urlsToCache = [
  '/display/hello.html'
];

// Set the callback for the install step
self.addEventListener('install', function(event) {
console.log('SW: installing');
 //  Perform install steps
 //  Will do offline once add and addAll work
  // event.waitUntil(
  //     caches.open(CACHE_NAME)
  //         .then(function(cache) {
  //           console.log('OPENED CACHE: caching ' + urlsToCache[0]);
  //           return cache.add(urlsToCache[0]);
  //         }), function(err) {
  //           console.log('ERROR RESOLVING PROMISE ' + err);
  //         }
  //     );
});


self.addEventListener('activate', function(event) {
  console.log("SW activated");
});

// Callback for the fetch event
self.addEventListener('fetch', function(event) {
  console.log('FETCH EVENT HANDLING');
  var fetchRequest = event.request.clone();
  console.log('got fetch request for ' + fetchRequest.url);
  if (fetchRequest.url == urlsToCache[0]) {
    event.respondWith(new Response("Hello world from SW LOG7!"));
  }
  // event.respondWith(
  //   caches.match(event.request)
  //     .then(function(response) {
  //       // Cache hit - return response
  //       if (response) {
  //         console.log('returning cached response :' + response );
  //         return response;
  //       }
  //       console.log('going to the network');
  //       return fetch(event.request);
  //     }
  //   )
  // );
  // console.log('going to the network');
  return fetch(event.request);
});

function notify(title, message) {
    var options = {
        body: message,
        tag: 'soccer',
        icon: '/static/cat.png'
    };
    return self.registration.showNotification(title, options);
}

function notifyEvent(event) {
    var title = "Final whistle in " + event.league;
    var message = event.home_team + " " + event.home_score + "-"
        + event.visitor_team + " " + event.visitor_score;
    return notify(title, message);
}

this.addEventListener('push', function(evt) {
    console.log('PUSH EVENT RECEIVED');
    // var title = "This is cool";
    // var message = "Notification";
    // var options = {
    //     body: message,
    //     tag: 'soccer',
    //     icon: '/static/cat.png'
    // };
    // return self.registration.showNotification(title, options);
  var day = new Date();
  try {
    soccerDB.open(function(ev) {
      fetchAndStore(day.getDate(), day.getMonth() + 1, day.getFullYear(), notifyEvent);
    });
  } catch(err) {
    notify("Updated Scores available", "Click to check them out");
  }

});

this.addEventListener('notificationclick', function(evt) {
    console.log("SW notificationclick");
    evt.notification.close();
        // Enumerate windows, and call window.focus(), or open a new one.
    evt.waitUntil(clients.matchAll({
        type: "window",
        includeUncontrolled: true
    }).catch(function(ex) {
        // Chrome doesn't yet support includeUncontrolled:true before M43
        if (ex.name != "NotSupportedError")
            throw ex;
        return clients.matchAll({
            type: "window",
            includeUncontrolled: false
        });
    }).then(function(clientList) {
        for (var i = 0; i < clientList.length; i++) {
            var client = clientList[i];
            if (client.focus)
                return client.focus();
        }
        if (clients.openWindow)
            return clients.openWindow("/display/soccer_offline");
    }));
});
