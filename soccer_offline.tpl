<!doctype html>
<html><head>
    <title>Soccer Results</title>
    <meta name="viewport" content="width=device-width, user-scalable=no">
    <link rel="manifest" href="/manifest.json">
    <link rel="icon" type="image/png" href="/static/hangouts.png" sizes="42x42">
    <link href="/static/roboto.css" rel="stylesheet" type="text/css">
    <link href="/static/soccer_home.css" rel="stylesheet" type="text/css">

    <!-- Polymer includes -->
    <link rel="import" href="/static/components/core/components/core-toolbar/core-toolbar.html">
    <link rel="import" href="/static/components/soccer/soccer-result.html">
    <link rel="import" href="/static/components/soccer/soccer-results.html">
    <link rel="import" href="/static/components/soccer/sports-tabs.html">

</head>

<body unresolved>
  <core-toolbar>
    <sports-tabs id="tabs" self-end>
    </sports-tabs>
  </core-toolbar>

  <div id="result-elements"> </div>
  <input id="subscribe" type=button value="Subscribe to push!"/>
  <a href ="/static/hello.html"> SW CHECK </a>
  <p id="log"> </p>
  <script>
    var $ = document.querySelector.bind(document);
    // Fetch scores related messages
    function fetchScores(day, month, year) {
      var promise = new Promise(function(resolve, reject) {
        var req = new XMLHttpRequest();
        var today = new Date()
        req.open("GET", "/collect/soccer?day=" + day +
                  "&month=" + month +
                  "&year=" + year);
        req.onload = function() {
          if (req.status != 200) {
            reject("Error");
          }
	  console.log(req.responseText);
          var results = JSON.parse(req.responseText);
          resolve(results);
        };
        req.send();
      });
      return promise;
    }

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
      for (i = -4; i <= 5; i++) {
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
	    fetchAndDisplay(e.target.day, e.target.month, e.target.year)});
        $('#tabs').appendChild(node);
      }
      $('#tabs').selected = formatDate(getDate(0));
    }

    function fillTab(result) {
      console.log(result);
      var results = document.createElement("soccer-results");
      results.id = "myresult";
      results.results = result;
      var node = $('#result-elements');
      while (node.firstChild) {
	  node.removeChild(node.firstChild);
      }
      node.appendChild(results);
    }

    function fetchAndDisplay(day, month, year) {
	fetchScores(day, month, year).then(function(result) {
	    fillTab(result["laliga"])
	}, function(err) {
	    alert("Error " + err);
	});
    }

    function subscribeForPush() {
      console.log("subscribeForPush");
      navigator.serviceWorker.ready.then(function(swr) {
        console.log("ACTIVE");
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
      pushManager.subscribe().then(function(ps) {
        console.log(JSON.stringify(ps));
        sendSubscriptionToBackend(ps.endpoint, ps.subscriptionId);
      }, function(err) {
        $("#log").textContent("API call unsuccessful! " + err);
      });
    }

    function sendSubscriptionToBackend(endpoint, subscriptionId) {
      console.log("Sending subscription to " + location.hostname + "...");
      $("#log").textContent = "Sending subscription to " + location.hostname + "...";
      // var formData = new FormData();
      // formData.append('username', $('#username').value);
      // formData.append('endpoint', endpoint);
      // formData.append('subscription_id', subscriptionId);
      // var xhr = new XMLHttpRequest();
      // xhr.onload = function() {
      //   if (('' + xhr.status)[0] != '2') {
      //     setStatus('join', 'fail', "Server error " + xhr.status
      //         + ": " + xhr.statusText);
      //   } else {
      //     setStatus('join', 'success', "Subscribed.");
      //     showChatScreen(false);
      //   }
      // };
      // xhr.onerror = xhr.onabort = function() {
      //   setStatus('join', 'fail', "Failed to send subscription ID!");
      // };
      // xhr.open('POST', '/chat/subscribe');
      // xhr.send(formData);
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
      navigator.serviceWorker.register('/static/soccer_sw.js').then(function(registration) {
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
      if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register('/static/soccer_sw.js').then(function(registration) {
          // Registration was successful
          console.log('ServiceWorker registration successful with scope: ', registration.scope);
        }).catch(function(err) {
          // registration failed :(
          console.log('ServiceWorker registration failed: ', err);
        });
      }

      $('#subscribe').addEventListener('click', function(event) {
        event.preventDefault();
        //subscribeForNotifications();
      });


    }

    start();
    createTabs();
    fetchAndDisplay(30, 4, 2015);

    </script>

</body></html>
