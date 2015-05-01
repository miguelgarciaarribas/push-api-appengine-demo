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

    createTabs(); 
    fetchAndDisplay(30, 4, 2015);

    </script>

</body></html>
