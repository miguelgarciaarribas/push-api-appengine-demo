<!doctype html>
<html><head>
    <title>My Chat App</title>
    <meta name="viewport" content="width=device-width, user-scalable=no">
    <link rel="manifest" href="/manifest.json">
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
        .action-bar > .action-buttons {
            float: right;
            font-size: 20px;
        }
        .action-bar > .action-buttons > #logout {
            display: inline-block;
            cursor: pointer;
            padding: 0 24px;
            vertical-align: top;
            color: white;
            font-size: 14px;
            font-weight: bold;
            text-transform: uppercase;
            text-decoration: none;
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
        <div class="action-bar">My Team chat</div>
        <form id="join-form">
            <label>Username: <input type="text" id="username"></label><br>
            <button>Join chatroom</button><span id="join-result"></span><span id="join-resultLink"></span>
        </form>
    </section>
    <section id="chat-page">
        <div id="workaround-header"></div>
        <div class="action-bar">
            My Team chat
            <div class="action-buttons">
                <span id="active-username"></span>
                <a id="logout">Logout</a>
            </div>
        </div>
        <pre id="incoming-messages"></pre>
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
            // TODO: Fix this in Chrome!
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
        var hasPush = !!window.PushManager;
        var hasNotification =
                !!window.ServiceWorkerRegistration &&
                !!ServiceWorkerRegistration.prototype.showNotification;
        var hasServiceWorker = !!navigator.serviceWorker;
        var supportsPush = hasPush && hasNotification && hasServiceWorker;
        if (!supportsPush) {
            if (!hasPush || !hasServiceWorker) {
                var whatsMissing = hasPush ? "ServiceWorker" : hasServiceWorker ? "push messaging" : "push messaging or ServiceWorker";
                setBothStatuses('fail', "Your browser does not support " + whatsMissing + "; you won't be able to receive messages.");
            } else if (!hasNotification) {
                setBothStatuses('fail', "Your browser doesn't support showing notifications from a Service Worker; you won't be able to receive messages when the page is not open");
            }
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
            navigator.serviceWorker.getRegistration('/chat/').then(function(r) {
                // Unregistering the SW will also unsubscribe from Push.
                if (r) return r.unregister();
            }).then(function() {
                return localforage.clear();
            }).then(function() {
                location.reload();
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

            navigator.serviceWorker.register('/chat/sw.js', { scope: "/chat/" })
                                   .then(function(sw) {
                requestPermission();
            }, function(error) {
                console.error(error);
                setStatus('join', 'fail', "SW registration rejected: " + error);
            });
        }

        function requestPermission() {
            if (!hasNotification) {
                subscribeForPush();
                return;
            }
            Notification.requestPermission(function(permission) {
                if (permission == "granted") {
                    subscribeForPush();
                    return;
                }
                $('#join-form > button').disabled = false;
                if (permission == "denied") {
                    setStatus('join', 'fail', "Notification permission denied. "
                                              + "Reset it via Page Info.");
                } else { // "default"
                    // This never currently gets triggered in Chrome, due to
                    // https://crbug.com/434547 :-(
                    setStatus('join', 'fail', "Notification permission prompt "
                                              + "dismissed. Reload to try "
                                              + "again.");
                }
            });
        }

        function subscribeForPush() {
            console.log("subscribeForPush");
            navigator.serviceWorker.ready.then(function(swr) {
                // TODO: Ideally we wouldn't have to check this here, since
                // the hasPush check earlier would guarantee it.
                if (!swr.pushManager) {
                    setBothStatuses('fail', "Your browser does not support push messaging; you won't be able to receive messages.");
                    showChatScreen(false);
                } else {
                    doSubscribe(swr.pushManager);
                }
            });
        }

        function doSubscribe(pushManager) {
            pushManager.subscribe().then(function(ps) {
                console.log(JSON.stringify(ps));
                sendSubscriptionToBackend(ps.endpoint, ps.subscriptionId);
            }, function(err) {
                setStatus('join', 'fail', "API call unsuccessful! " + err);
            });
        }

        function sendSubscriptionToBackend(endpoint, subscriptionId) {
            console.log("Sending subscription to " + location.hostname + "...");

            var formData = new FormData();
            formData.append('endpoint', endpoint);
            formData.append('subscription_id', subscriptionId);

            var xhr = new XMLHttpRequest();
            xhr.onload = function() {
                if (('' + xhr.status)[0] != '2') {
                    setStatus('join', 'fail', "Server error " + xhr.status
                                              + ": " + xhr.statusText);
                } else {
                    setStatus('join', 'success', "Subscribed.");
                    showChatScreen(false);
                }
            };
            xhr.onerror = xhr.onabort = function() {
                setStatus('join', 'fail', "Failed to send subscription ID!");
            };
            xhr.open('POST', '/chat/subscribe');
            xhr.send(formData);
        }

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

        $('#send-form').addEventListener('submit', function(evt) {
            evt.preventDefault();
            console.log("Sending message to " + location.hostname + "...");
            setStatus('send', '', "");

            var message = $('#message').value;
            message = message.replace(":)", "😃");  // Smiley

            var formData = new FormData();
            formData.append('message',
                $('#username').value + ": " + message);

            var xhr = new XMLHttpRequest();
            xhr.onload = function() {
                var statusString = xhr.status + ": " + xhr.statusText;
                if (('' + xhr.status)[0] != '2') {
                    setStatus('send', 'fail', "Server error " + statusString,
                              xhr.responseText);
                } else {
                    setStatus('send', 'success', "Sent, status " + statusString,
                              xhr.responseText);
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
