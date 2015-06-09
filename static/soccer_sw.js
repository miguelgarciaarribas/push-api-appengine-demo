var CACHE_NAME = 'my-site-cache-v1';
var urlsToCache = [
  '/static/hello.html'
];

// Set the callback for the install step
self.addEventListener('install', function(event) {
 //  Perform install steps
  event.waitUntil(
     caches.open(CACHE_NAME)
       .then(function(cache) {
         console.log('OPENED CACHE: caching ' + urlsToCache[0]);
         return cache.add(urlsToCache[0]); // return cache[urlsToCache[0]];
       }), function(err) {
         console.log('ERROR RESOLVING PROMISE ' + err);
       }
      );
});


self.addEventListener('activate', function(event) {
  console.log("SW activated");
});

// Callback for the fetch event
self.addEventListener('fetch', function(event) {
  console.log('FETCH EVENT HANDLING');
  var fetchRequest = event.request.clone();
  console.log('got fetch request for ' + fetchRequest);
  event.respondWith(
    caches.match(event.request)
      .then(function(response) {
        // Cache hit - return response
        if (response) {
          console.log('returning cached response :' + response );
          return response;
        }
        console.log('going to the network');
        return fetch(event.request);
      }
    )
  );
});


this.addEventListener('push', function(evt) {
console.log('PUSH EVENT RECEIVED');
});
