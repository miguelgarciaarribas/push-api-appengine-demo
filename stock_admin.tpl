<!doctype html>
<html><head>
    <title>Stocks App Admin</title>
    <meta name="viewport" content="width=device-width, user-scalable=no">
    <style>
        body {
            margin: 5vmin;
            font-family: sans-serif;
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
    <h1>Stocks App Admin</h1>
    <button id="drop-button">Trigger price drop</button><span id="drop-result"></span>
    <script>
        var $ = document.querySelector.bind(document);

        function setStatus(buttonName, className, text) {
            var result = $('#' + buttonName + '-result');
            result.textContent = " " + text;
            if (!text)
                return;
            result.className = className;
            console.log(buttonName + " " + className + ": " + text);
        }

        $('#drop-button').addEventListener('click', function() {
            console.log("Sending price drop to johnme-gcm.appspot.com...");
            setStatus('drop', '', "");

            var xhr = new XMLHttpRequest();
            xhr.onload = function() {
                if (('' + xhr.status)[0] != '2') {
                    setStatus('drop', 'fail', "Server error " + xhr.status
                                              + ": " + xhr.statusText);
                } else {
                    setStatus('drop', 'success', "Triggered.");
                }
            };
            xhr.onerror = xhr.onabort = function() {
                setStatus('drop', 'fail', "Failed to send!");
            };
            xhr.open('POST', '/stock/trigger-drop');
            xhr.send();
        }, false);
    </script>

</body></html>