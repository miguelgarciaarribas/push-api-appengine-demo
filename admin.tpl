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
    <button id="drop-stock-button">Trigger price drop</button><span id="drop-result"></span>
    <br><br><br>
    <button id="clear-stock-button">Clear all /stock registrations</button><span id="clear-stock-result"></span>
    <br><br><br>
    <button id="clear-chat-button">Clear all /chat registrations</button><span id="clear-chat-result"></span>
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

        $('#drop-stock-button').addEventListener('click', function() {
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

        $('#clear-stock-button').addEventListener('click', function() {
            clearRegistrations('stock');
        }, false);
        $('#clear-chat-button').addEventListener('click', function() {
            clearRegistrations('chat');
        }, false);

        function clearRegistrations(type) {
            console.log("Sending clear " + type + " registrations to johnme-gcm.appspot.com...");
            var statusId = 'clear-' + type;
            setStatus(statusId, '', "");

            var xhr = new XMLHttpRequest();
            xhr.onload = function() {
                if (('' + xhr.status)[0] != '2') {
                    setStatus(statusId, "Server error " + xhr.status
                                        + ": " + xhr.statusText);
                } else {
                    setStatus(statusId, 'success', "Cleared.");
                }
            };
            xhr.onerror = xhr.onabort = function() {
                setStatus(statusId, 'fail', "Failed to send!");
            };
            xhr.open('POST', '/' + type + '/clear-registrations');
            xhr.send();
        }
    </script>

</body></html>