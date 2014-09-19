<!doctype html>
<html><head>
    <title>Chat App</title>
    <meta name="viewport" content="width=device-width, user-scalable=no">
    <link rel="icon" type="image/png" href="/static/hangouts.png" sizes="42x42">
    <link href="/static/roboto.css" rel="stylesheet" type="text/css">
    <style>
        html, body {
            font-family: 'Roboto', sans-serif;
            margin: 0;
        }
        #loading-page {
            position: fixed;
            top: 0; right: 0; bottom: 0; left: 0;
            background: white;
            z-index: 2;
        }
        #login-page {
            position: fixed;
            top: 0; right: 0; bottom: 0; left: 0;
            background: white;
            opacity: 1;
            transition: opacity 0.5s;
        }
        #workaround-header {
            display: none;
            height: 56px;
            background-color: #0a7e07;
        }
        .action-bar {
            background-color: #259b24;
            color: white;

            line-height: 64px;
            font-size: 24px;

            background-image: url("/static/hamburger.svg");
            background-size: 24px 24px;
            background-repeat: no-repeat;
            background-position: 24px center;
            padding-left: 72px;
        }
        #join-form, #send-form, #incoming-messages {
            margin: 1em;
        }
        #join-form, #join-form *, #send-form, #send-form *, #incoming-messages {
            font-size: 16px;
            vertical-align: middle;
        }
        #message {
            line-height: 32px;
        }
        #send-form > button {
            width: 48px;
            height: 48px;
            background: url(/static/send.png);
            background-size: contain;
            border: none;
            padding: 0;
            margin: 0;
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
    <section id="loading-page"></section>
    <section id="login-page">
        <div class="action-bar">Team chat</div>
        <form id="join-form">
            <label>Username: <input type="text" id="username"></label><br>
            <button>Join chatroom</button><span id="join-result"></span><span id="join-resultLink"></span>
        </form>
    </section>
    <section id="chat-page">
        <div id="workaround-header"></div>
        <div class="action-bar">Team chat</div>
        <pre id="incoming-messages"></pre>
        <div>You are logged in as <div id="you-are-logged-in-username"></div></div>
        <form id="send-form">
            <input type="text" id="message">
            <button></button><span id="send-result"></span><span id="send-resultLink"></span>
        </form>
    </section>
    <script src="/static/localforage.js"></script>
    <script>
        var $ = document.querySelector.bind(document);

        function crazyHack() {
            if (window.outerHeight == 0) {
                setTimeout(crazyHack, 32);
                return;
            }
            // CRAZY HACK: When opening Chrome after receiving a push message in
            // the background, the top controls manager can get confused,
            // causing the omnibox to permanently overlap the top 56 pixels of
            // the page. Detect this and work around it with a spacer div.
            console.log("screen.height = " + screen.height);
            console.log("window.outerHeight = " + window.outerHeight);
            if (screen.height - window.outerHeight == 25) {
                $('#workaround-header').style.display = 'block';
            }
        }
        crazyHack();
        window.addEventListener("resize", crazyHack);

        function setStatus(buttonName, className, text, responseText) {
            var result = $('#' + buttonName + '-result');
            var resultLink = $('#' + buttonName + '-resultLink');
            if (className == 'success')
                result.textContent = ""; // Don't bother notifying success.
            else
                result.textContent = " " + text;
            if (responseText)
                resultLink.innerHTML = " <a href='data:text/html," + encodeURIComponent(responseText) + "'>(Full message)</a>";
            else
                resultLink.innerHTML = "";
            if (!text)
                return;
            result.className = className;
            resultLink.className = className;
            if (buttonName == 'join' && className == 'fail')
                $('#join-form > button').disabled = false;
            console.log(buttonName + " " + className + ": " + text);
        }

        var hasPush = !!navigator.push;
        var hasNotification = !!window.Notification;
        var hasServiceWorker = !!navigator.serviceWorker;
        var supportsPush = hasPush && hasNotification && hasServiceWorker;
        if (!supportsPush) {
            function setBothStatuses(className, message) {
                setStatus('join', className, message);
                setStatus('send', className, message);
            }
            if (!hasPush || !hasServiceWorker) {
                var whatsMissing = hasPush ? "ServiceWorker" : hasServiceWorker ? "push messaging" : "push messaging or ServiceWorker";
                setBothStatuses('fail', "Your browser does not support " + whatsMissing + "; you won't be able to receive messages.");
            } else if (!hasNotification) {
                setBothStatuses('fail', "Your browser doesn't support notifications; you won't be able to receive messages when the page is not open");
            }
        }

        var usernamePromise = localforage.getItem('username');
        window.addEventListener('DOMContentLoaded', function() {
            usernamePromise.then(function(username) {
                var AUTO_REGISTER_USERNAME = '{{user_from_get}}';
                if (username != null) {
                    // We've already registered.
                    $('#username').value = username;
                    showChatScreen(true);
                } else if (AUTO_REGISTER_USERNAME) {
                    // Try to auto-register.
                    $('#username').value = AUTO_REGISTER_USERNAME;
                    joinChat();
                }
                $('#you-are-logged-in-username').textContent = $('#username').value;
                $('#loading-page').style.display = 'none';
            });
        });

        $('#join-form').addEventListener('submit', function(evt) {
            evt.preventDefault();
            joinChat();
        });

        function joinChat() {
            $('#join-form > button').disabled = true;
            setStatus('join', '', "");

            console.log("join-form submit handler");
            if (!hasPush || !hasServiceWorker) {
                showChatScreen(false);
                return;
            }

            navigator.serviceWorker.register('/static/chat-sw.js').then(function(sw) {
                registerForPush();
            }, function(error) {
                console.error(error);
                setStatus('join', 'fail', "SW registration rejected: " + error);
            });
        }

        function registerForPush() {
            console.log("registerForPush");
            var SENDER_ID = '{{sender_id}}';
            navigator.push.register(SENDER_ID).then(function(pr) {
                console.log(JSON.stringify(pr));
                sendRegistrationToBackend(pr.pushEndpoint,
                                          pr.pushRegistrationId);
            }, function(err) {
                setStatus('join', 'fail', "API call unsuccessful! " + err);
                // HACK: Force a reload with auto-register enabled, to work
                // around a bug in Chrome's current Push API implementation,
                // that makes it require a controlling instead of active SW.
                location.search = '?user='
                                + encodeURIComponent($('#username').value);
            });
        }

        function sendRegistrationToBackend(endpoint, registrationId) {
            console.log("Sending registration to " + location.hostname + "...");

            var formData = new FormData();
            formData.append('endpoint', endpoint);
            formData.append('registration_id', registrationId);

            var xhr = new XMLHttpRequest();
            xhr.onload = function() {
                if (('' + xhr.status)[0] != '2') {
                    setStatus('join', 'fail', "Server error " + xhr.status
                                              + ": " + xhr.statusText);
                } else {
                    setStatus('join', 'success', "Registered.");
                    showChatScreen(false);
                }
            };
            xhr.onerror = xhr.onabort = function() {
                setStatus('join', 'fail', "Failed to send registration ID!");
            };
            xhr.open('POST', '/chat/register');
            xhr.send(formData);
        }

        function showChatScreen(immediate) {
            if (immediate) {
                $('#login-page').style.display = 'none';
                return;
            }
            localforage.setItem('username', $('#username').value);
            $('#you-are-logged-in-username').textContent = $('#username').value;
            $('#login-page').style.opacity = 0;
            setTimeout(function() {
                $('#login-page').style.display = 'none';
            }, 510);
        }

        function updateText() {
            localforage.getItem('messages').then(function(text) {
                $('#incoming-messages').textContent = text;
                // Poll for new messages; TODO: instead, postMessage from SW.
                setTimeout(updateText, 100);
            });
        }
        updateText();

        $('#send-form').addEventListener('submit', function(evt) {
            evt.preventDefault();
            console.log("Sending message to " + location.hostname + "...");
            setStatus('send', '', "");

            var formData = new FormData();
            formData.append('message',
                $('#username').value + ": " + $('#message').value);

            var xhr = new XMLHttpRequest();
            xhr.onload = function() {
                if (('' + xhr.status)[0] != '2') {
                    setStatus('send', 'fail', "Server error " + xhr.status
                                              + ": " + xhr.statusText, xhr.responseText);
                } else {
                    setStatus('send', 'success', "Triggered.");
                    $('#message').value = "";
                }
            };
            xhr.onerror = xhr.onabort = function() {
                setStatus('send', 'fail', "Failed to send!");
            };
            xhr.open('POST', '/chat/send');
            xhr.send(formData);
        });
    </script>

</body></html>
