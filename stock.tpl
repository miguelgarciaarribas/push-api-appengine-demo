<!doctype html>
<html><head>
    <title>Stocks App (SW)</title>
    <meta name="viewport" content="width=device-width, user-scalable=no">
    <style>
        body {
            margin: 5vmin;
            font-family: sans-serif;
        }
        #chart {
            margin-left: -5vmin;
            margin-right: -5vmin;
            width: 100vmin;
            height: 60vmin;
        }
        .success {
            color: green;
            font-style: italic;
        }
        .fail {
            color: red;
            font-style: italic;
            font-weight: bold;
        }
    </style>
</head><body>
    <div id="chart"></div>
    <button id="register-button">Register for price alerts</button><span id="register-result"></span><br>
    <script src="https://www.google.com/jsapi"></script>
    <script>
        var $ = document.querySelector.bind(document);

        function setStatus(buttonName, className, text) {
            var result = $('#' + buttonName + '-result');
            result.textContent = " " + text;
            if (!text)
                return;
            result.className = className;
            if (buttonName == 'register' && className == 'fail')
                $('#register-button').disabled = false;
            console.log(buttonName + " " + className + ": " + text);
        }

        if (!('push' in navigator) || !('Notification' in window)) {
            setStatus('register', 'fail',
                      "Your browser does not support push notifications.");
            $('#register-button').disabled = true;
        }

        google.load('visualization', '1', {packages:['corechart']});
        google.setOnLoadCallback(drawChart);
        function drawChart(mayData) {
            var color = 'blue';
            var dataArray = [
                ["Month", "Share price"],
                ["Jan",  1000],
                ["Feb",  1170],
                ["Mar",  860],
                ["Apr",  1030]
            ];
            if (mayData && mayData.length == 2) {
                dataArray.push(mayData);
                if (mayData[1] <= 1030 / 2)
                    color = 'red';
            }
            var data = google.visualization.arrayToDataTable(dataArray);

            var options = {
                title: "NASDAQ: FOOBAR",
                colors: [color],
                hAxis: {title: "Month"},
                vAxis: {title: "Share price", minValue: 0},
                legend: {position: 'none'}
            };

            var chart = new google.visualization.AreaChart($('#chart'));
            chart.draw(data, options);
        }

        $('#register-button').addEventListener('click', function() {
            $('#register-button').disabled = true;
            setStatus('register', '', "");

            navigator.serviceWorker.register('/static/stock-sw.js').then(function(sw) {
                registerForPush();
            }, function(error) {
                console.error(error);
                setStatus('register', 'fail', "SW registration rejected!");
            });
        }, false);

        function registerForPush() {
            var SENDER_ID = 'INSERT_SENDER_ID';
            navigator.push.register(SENDER_ID).then(function(pr) {
                console.log(JSON.stringify(pr));
                sendRegistrationToBackend(pr.pushEndpoint,
                                          pr.pushRegistrationId);
            }, function() {
                setStatus('register', 'fail', "API call unsuccessful!");
            });
        }

        function sendRegistrationToBackend(endpoint, registrationId) {
            console.log("Sending registration to johnme-gcm.appspot.com...");

            var formData = new FormData();
            formData.append('endpoint', endpoint);
            formData.append('registration_id', registrationId);

            var xhr = new XMLHttpRequest();
            xhr.onload = function() {
                if (('' + xhr.status)[0] != '2') {
                    setStatus('register', 'fail', "Server error " + xhr.status
                                                  + ": " + xhr.statusText);
                } else {
                    setStatus('register', 'success', "Registered.");
                }
            };
            xhr.onerror = xhr.onabort = function() {
                setStatus('register', 'fail', "Failed to send registration ID!");
            };
            xhr.open('POST', '/stock/register');
            xhr.send(formData);
        }
    </script>

</body></html>