<!doctype html>
<html><head>
    <title>Soccer Results</title>
    <meta name="viewport" content="width=device-width, user-scalable=no">
    <link rel="manifest" href="/manifest.json">
    <link rel="icon" type="image/png" href="/static/hangouts.png" sizes="42x42">
    <link href="/static/roboto.css" rel="stylesheet" type="text/css">
    <link href="/static/soccer_home.css" rel="stylesheet" type="text/css">

</head><body>
    <section id="loading-page"></section>
    <section id="login-page">
        <div class="action-bar">My Soccer resuls</div>
        <form id="join-form">
            <label>Username: <input type="text" id="username"></label><br>
            <button>Join chatroom</button><span id="join-result"></span><span id="join-resultLink"></span>
        </form>
    </section>
    <section id="chat-page">
        <div class="action-bar">
            My Soccer Results
            <div class="action-buttons">
                <span id="active-username"></span>
                <a id="logout">Logout</a>
            </div>
        </div>
        <pre id="incoming-messages"></pre>
        <pre id="soccer-results"></pre>
        <form id="send-form">
            <input type="text" id="message">
            <button></button><span id="send-result"></span><span id="send-resultLink"></span>
        </form>
    </section>
    <script src="/static/localforage.js"></script>
    <script>
        var $ = document.querySelector.bind(document);

        function setStatus(buttonName, className, text, responseText) {
            var result = $('#' + buttonName + '-result');
            var resultLink = $('#' + buttonName + '-resultLink');
            if (className == 'success')
                result.textContent = ""; // Don't bother notifying success.
            else
                result.textContent = " " + text;
            if (responseText) {
                var mimeType = /^\s*</.test(responseText) ? 'text/html'
                                                          : 'text/plain';
                resultLink.innerHTML = " <a href='data:" + mimeType + ","
                                     + encodeURIComponent(responseText)
                                     + "'>(Debug info)</a>";
            } else {
                resultLink.innerHTML = "";
            }
            if (!text)
                return;
            result.className = className;
            resultLink.className = className;
            if (buttonName == 'join' && className == 'fail')
                $('#join-form > button').disabled = false;
            console.log(buttonName + " " + className + ": " + text
                        + (responseText ? "\n" + responseText : ""));
        }

        function setBothStatuses(className, message) {
            setStatus('join', className, message);
            setStatus('send', className, message);
        }

        var usernamePromise = localforage.getItem('username');
        window.addEventListener('DOMContentLoaded', function() {
            usernamePromise.then(function(username) {
                var AUTO_SUBSCRIBE_USERNAME = '{{user_from_get}}';
                if (username != null) {
                    // We've already subscribed.
                    // TODO: Check SW hasn't been unregistered (e.g. because
                    // user cleared it in chrome://serviceworker-internals).
                    $('#username').value = username;
                    showChatScreen(true);
                } else if (AUTO_SUBSCRIBE_USERNAME) {
                    // Try to auto-subscribe.
                    $('#username').value = AUTO_SUBSCRIBE_USERNAME;
                    joinChat();
                } else {
                    $('#username').focus();
                }
                $('#active-username').textContent = $('#username').value;
                $('#loading-page').style.display = 'none';
            });
        });


        $('#logout').addEventListener('click', function(evt) {
          alert('LOGOUT');
        });


        function showChatScreen(immediate) {
            $('#message').focus();
            if (immediate) {
                $('#login-page').style.display = 'none';
                return;
            }
            localforage.setItem('username', $('#username').value);
            $('#active-username').textContent = $('#username').value;
            $('#login-page').style.opacity = 0;
            setTimeout(function() {
                $('#login-page').style.display = 'none';
            }, 510);
        }


       // Fetch scores related messages
        function fetchScores() {
            var req = new XMLHttpRequest();
            req.open("GET", "/collect/soccer");
            req.onload = function() {
                var results = JSON.parse(req.responseText);
                console.log(results);
                $('#soccer-results').textContent = results;
                //localforage.setItem('messages', req.responseText)
                //           .then(function() { updateText(); });
            };
            req.send();
        }
        fetchScores();

        /// Fetch chat messages related methods To be obsoleted
        function updateText() {
            localforage.getItem('messages').then(function(text) {
                $('#incoming-messages').textContent = text;
                // Poll for new messages; TODO: instead, postMessage from SW.
                setTimeout(updateText, 100);
            });
        }
        function fetchMessages() {
            var req = new XMLHttpRequest();
            req.open("GET", "/chat/messages");
            req.onload = function() {
                localforage.setItem('messages', req.responseText)
                           .then(function() { updateText(); });
            };
            req.send();
        }
        fetchMessages();


    </script>

</body></html>
