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
  <div id="single-result"> </div>
    <script>
    var $ = document.querySelector.bind(document);
    // Fetch scores related messages
    function fetchScores() {
        var req = new XMLHttpRequest();
        req.open("GET", "/collect/soccer");
        req.onload = function() {
            var results = JSON.parse(req.responseText);
            console.log(results);
            // $('#result-elements').textContent = results;
            //localforage.setItem('messages', req.responseText)
            //           .then(function() { updateText(); });
        };
        req.send();
    }

    function formatDate(decalage) {
	var weekday = new Array(7);
	weekday[0]=  "SUN";
	weekday[1] = "MON";
	weekday[2] = "TUE";
	weekday[3] = "WED";
	weekday[4] = "THU";
	weekday[5] = "FRI";
	weekday[6] = "SAT";

       var today = new Date();
       var date = new Date(today.getFullYear(), today.getMonth(),
                           today.getDate() + decalage, 0, 0, 0, 0);
       return weekday[(date.getDay())] + "/" + date.getDate();
    }

    function createTabs() {
      for (i = -4; i <= 5; i++) {
	var node = document.createElement("paper-tab");
        node.id = formatDate(i);
	var text = document.createTextNode(formatDate(i));
	node.appendChild(text);
        $('#tabs').appendChild(node);
      }
      $('#tabs').selected = formatDate(0);
      var result1 = document.createElement("soccer-result");
      result1.innerHTML = "<h2> REal Madrid</h2> <p> Hello </p>";
      var result2 = document.createElement("soccer-result");
      result2.innerHTML = "<h2> Atl Madrid </h2> <p> Hello </p>";
      var results = document.createElement("soccer-results");
      results.id = "myresult";
      results.results = [result1, result2];
      $('#result-elements').appendChild(results);

      var result3 = document.createElement("soccer-result");
      result3.innerHTML = "<h2> EIBAR </h2> <p> Hello </p>";
      $('#single-result').appendChild(result3);

    }

    fetchScores();
    createTabs();
    </script>

</body></html>
