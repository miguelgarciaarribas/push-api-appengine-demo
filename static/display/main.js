'use strict';
var $ = document.querySelector.bind(document);

function formatDate(date) {
    var weekday = new Array(7);
    weekday[0]=  "SUN";
    weekday[1] = "MON";
    weekday[2] = "TUE";
    weekday[3] = "WED";
    weekday[4] = "THU";
    weekday[5] = "FRI";
    weekday[6] = "SAT";

    return weekday[(date.getDay())] + "/" + date.getDate();
}

function getDate(decalage) {
   var today = new Date();
   return new Date(today.getFullYear(), today.getMonth(),
                   today.getDate() + decalage, 0, 0, 0, 0);
}

function createTabs(result) {
  console.log("results");
  console.log(result);
  for (var i = -4; i <= 5; i++) {
    var node = document.createElement("paper-tab");
    var date = getDate(i);
    var printDate = formatDate(date);
    node.id = printDate;
    node.day = date.getDate();
    node.month = date.getMonth() +1;
    node.year = date.getFullYear();
    var text = document.createTextNode(printDate);
    node.appendChild(text);
    node.addEventListener("click", function(e) {
      fillTabFromCache(e.target.day, e.target.month, e.target.year)});
    $('#tabs').appendChild(node);
  }
  $('#tabs').selected = formatDate(getDate(0));
}

function fillTab(result) {
  var node = $('#result-elements');
  while (node.firstChild) {
    node.removeChild(node.firstChild);
  }
  var results = document.createElement("soccer-results");
  results.id = "myresult";
  results.results = result;
  node.appendChild(results);
}

function fillTabFromCache(day, month, year) {
 soccerDB.fetchEvents(function(events) {
   var node = $('#result-elements');
   while (node.firstChild) {
     node.removeChild(node.firstChild);
   }
   var results = document.createElement("soccer-results");
   results.id = "myresult";

   results.results = events.filter(function(e) {
     var cond = e.day  == day && e.month == month &&
            e.year == year;
     return cond;
   });
   node.appendChild(results);
 });
}

function subscribeForPush() {
  console.log("subscribeForPush:" );
  navigator.serviceWorker.ready.then(function(swr) {
    console.log("ACTIVE: " + swr);
    // TODO: Ideally we wouldn't have to check this here, since
    // the hasPush check earlier would guarantee it.
    if (!swr.pushManager) {
      $("#log").textContent = "Your browser does not support push messaging; you won't be able to receive messages.";
    } else {
      doSubscribe(swr.pushManager);
    }
  }).catch(function(err){ $("#log").textContent = "oh oh.. " + err; });
}

function doSubscribe(pushManager) {
  pushManager.subscribe({userVisibleOnly: true}).then(function(ps) {
    console.log(JSON.stringify(ps));
    sendSubscriptionToBackend(ps.endpoint, ps.subscriptionId);
  }, function(err) {
    $("#log").textContent ="API call unsuccessful! " + err;
  });
}

function sendSubscriptionToBackend(endpoint, subscriptionId) {
  console.log("Sending subscription to " + location.hostname + "...");
  $("#log").textContent = "Sending subscription to " + location.hostname + "...";
  var formData = new FormData();
  formData.append('endpoint', endpoint);
  formData.append('subscription_id', subscriptionId);
  // TODO: Defaults to Atletico Madrid registrations, make it generic
  formData.append('team', 'Atletico Madrid');

  var xhr = new XMLHttpRequest();
  xhr.onload = function() {
    if (('' + xhr.status)[0] != '2') {
      $("#log").textContent = "Server error " + xhr.status
          + ": " + xhr.statusText;
    } else {
       $("#log").textContent = "Subscribed!";
    }
  };
  xhr.onerror = xhr.onabort = function() {
    $("#log").textContent = "Failed to send subscription ID!";
  };
  xhr.open('POST', '/subscribe/soccer');
  xhr.send(formData);
}

function subscribeForNotifications() {
  var hasPush = !!window.PushManager;
  var hasNotification =
      !!window.ServiceWorkerRegistration &&
      !!ServiceWorkerRegistration.prototype.showNotification;
  var hasServiceWorker = !!navigator.serviceWorker;
  var supportsPush = hasPush && hasNotification && hasServiceWorker;
  $('#subscribe').disabled = true;
  if (!hasPush || !hasServiceWorker) {
    $("#log").textContent("PUSH NOT AVAILABLE ON YOUR BROWSER");
    return;
  }
  navigator.serviceWorker.register('/display/soccer_sw.js', {scope: "/display/"}).then(function(registration) {
    console.log('ServiceWorker registration successful with scope: ', registration.scope);
    Notification.requestPermission(function(permission) {
      if (permission == "granted") {
        console.log("GRANTED!!");
        subscribeForPush();
        return;
      }
      if (permission == "denied") {
        $('#log').textContent ="Notification permission denied. "
            + "Reset it via Page Info.";
      } else { // "default"
        $('#log').textContent ="Notification permission prompt "
            + "dismissed. Reload to try "
            + "again.";
      }
    });
  });
}

// Loads the SW that will then take care of all requests
function start() {
  $('#subscribe').addEventListener('click', function(event) {
    event.preventDefault();
    subscribeForNotifications();
  });
  $('#refresh').addEventListener('click', function(event) {
    event.preventDefault();
    var day = getDate(0)
    fetchAndStore(day.getDate(), day.getMonth() + 1, day.getFullYear(), logNewEvent);
  });
  createTabs();
  soccerDB.open(function(ev) {
    for (var i = 0; i < 7 ; ++i) {
      var day = getDate(i)
      fetchAndStore(day.getDate(), day.getMonth(), day.getFullYear(), logNewEvent);
    }
  });
}



function logNewEvent(e) {
  console.log("New Event found " + e.home_team + " vs " + e.visitor_team);
}
