<!doctype html>
<html><head>
    <title>Stocks App Admin</title>
    <meta name="viewport" content="width=device-width, user-scalable=no">
    <script src="/static/admin.js"></script>
    <link rel="stylesheet" href="/static/admin.css">
</head><body>
    <h1>Stocks App Admin</h1>
    <button id="drop-stock-button">Trigger price drop</button><span id="drop-result"></span>
    <br><br><br>
    <button id="clear-stock-button">Clear all /stock registrations</button><span id="clear-stock-result"></span>
    <script>
        $('#drop-stock-button').addEventListener('click', function() {
            console.log("Sending price drop to " + location.hostname + "...");
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
    </script>
</body></html>