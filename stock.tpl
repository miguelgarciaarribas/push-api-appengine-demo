<!doctype html>
<html><head>
    <title>ChatApp</title>
    <meta name="viewport" content="width=device-width, user-scalable=no">
    <style>
        body {
            margin: 5vmin;
            /*display: flex;
            flex-direction: column;*/
        }
        #chart {
            width: 90vmin; height: 50vmin;
        }
        /*#login {
            flex: auto;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-self: center;
            align-items: flex-start;
        }*/
        button {
            margin-top: 1em;
        }
    </style>
</head><body>
    <div id="chart"></div>
    <button id="register-button">Register for price alerts</button>
    <div id="register-error"></div>
    <label>DEMO ONLY: <button id="drop-button">Trigger price drop</button></label>
    <script src="https://www.google.com/jsapi"></script>
    <script>
        var $ = document.querySelector;

        if (!('push' in navigator)) {
            $('#register-button').disabled = true;
            $('#register-error').innerHTML
                = "<b>Your browser does not support push messaging. Please use"
                + "the apk you were provided with.</b>";
        }

        google.load('visualization', '1', {packages:['corechart']});
        google.setOnLoadCallback(drawChart);
        function drawChart(mayData) {
            var dataArray = [
                ["Month", "Share price"],
                ["Jan",  1000],
                ["Feb",  1170],
                ["Mar",  660],
                ["Apr",  1030]
            ];
            if (mayData && mayData.length == 2)
                dataArray.push(mayData);
            var data = google.visualization.arrayToDataTable(dataArray);

            var options = {
                title: "NASDAQ: FOOBAR",
                hAxis: {title: "Month"},
                vAxis: {title: "Share price", minValue: 0},
                legend: {position: 'none'}
            };

            var chart = new google.visualization.AreaChart($('#chart'));
            chart.draw(data, options);
        }

        $('#register-button').addEventListener('click', function() {
            $('#register-button').disabled = true;
            navigator.push.register('INSERT_SENDER_ID')
                          .then(function(pr) {
                console.log(pr);
                sendRegistrationToBackend(pr.pushEndpoint,
                                          pr.pushRegistrationId);
            }, function() {
                console.log("Registration failed:", arguments);
            });
        }, false);

        function sendRegistrationToBackend(endpoint, registrationId) {
            console.log("Sending registration to johnme-gcm.appspot.com...");
            var formData = new FormData();
            formData.append('endpoint',
                            'https://android.googleapis.com/gcm/send');
            formData.append('registration_id', registrationId);
            var xhr = new XMLHttpRequest();
            xhr.onload = function() {
                console.log("Sent registration ID successfully.");
                $('#register-button').textContent = "Registered";

                navigator.push.addEventListener("push", onPush, false);
            };
            xhr.onerror = xhr.onabort = function() {
                console.log("Failed to send registration ID.");
            };
            xhr.open('POST', '/stock/register');
            xhr.send(formData);
        }

        function onPush(evt) {
            console.log(evt);
            alert("Incoming push message: " + evt.data);
            drawChart(JSON.parse(evt.data));
        }

        $('#drop-button').addEventListener('click', function() {
            console.log("Sending price drop to johnme-gcm.appspot.com...");
            var xhr = new XMLHttpRequest();
            xhr.onload = function() {
                console.log("Sent price drop successfully.");
            };
            xhr.onerror = xhr.onabort = function() {
                console.log("Failed to send price drop.");
            };
            xhr.open('POST', '/stock/trigger-drop');
            xhr.send();
        }, false);
    </script>

</body></html>