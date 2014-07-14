<!doctype html>
<html><head>
    <title>Chat App</title>
    <meta name="viewport" content="width=device-width, user-scalable=no">
    <style>
        #login-page {
            position: fixed;
            top: 0; right: 0; bottom: 0; left: 0;
            margin: 8px;
            background: white;
            opacity: 1;
            -webkit-transition: opacity 0.5s;
            transition: opacity 0.5s;
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
    <section id="login-page">
        <form id="join-form">
            <label>Username: <input type="text" id="username"></label><br>
            <button>Join chatroom</button><span id="join-result"></span>
        </form>
    </section>
    <section id="chat-page">
        <pre id="incoming-messages"></pre>
        <form id="send-form">
            <input type="text" id="message">
            <button>Send</button><span id="send-result"></span>
        </form>
    </section>
    <script src="/static/localforage.js"></script>
    <script>
        var $ = document.querySelector.bind(document);

        function setStatus(buttonName, className, text) {
            var result = $('#' + buttonName + '-result');
            result.textContent = " " + text;
            if (!text)
                return;
            result.className = className;
            if (buttonName == 'join' && className == 'fail')
                $('#join-form > button').disabled = false;
            console.log(buttonName + " " + className + ": " + text);
        }

        var supportsPush = ('push' in navigator) && ('Notification' in window);
        if (!supportsPush) {
            setStatus('join', 'fail',
                      "Your browser does not support push notifications; you won't be able to receive messages.");
        }

        $('#join-form').addEventListener('submit', function(evt) {
            evt.preventDefault();
            $('#join-form > button').disabled = true;
            setStatus('join', '', "");

            if (!supportsPush) {
                showChatScreen();
                return;
            }

            navigator.serviceWorker.register('/static/chat-sw.js').then(function(sw) {
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
                setStatus('join', 'fail', "API call unsuccessful!");
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
                    setStatus('join', 'fail', "Server error " + xhr.status
                                              + ": " + xhr.statusText);
                } else {
                    setStatus('join', 'success', "Registered.");
                    showChatScreen();
                }
            };
            xhr.onerror = xhr.onabort = function() {
                setStatus('join', 'fail', "Failed to send registration ID!");
            };
            xhr.open('POST', '/chat/register');
            xhr.send(formData);
        }

        function showChatScreen() {
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
            console.log("Sending message to johnme-gcm.appspot.com...");
            setStatus('send', '', "");

            var formData = new FormData();
            formData.append('message',
                $('#username').value + ": " + $('#message').value);

            var xhr = new XMLHttpRequest();
            xhr.onload = function() {
                if (('' + xhr.status)[0] != '2') {
                    setStatus('send', 'fail', "Server error " + xhr.status
                                              + ": " + xhr.statusText);
                } else {
                    setStatus('send', 'success', "Triggered.");
                }
            };
            xhr.onerror = xhr.onabort = function() {
                setStatus('send', 'fail', "Failed to send!");
            };
            xhr.open('POST', '/chat/send');
            xhr.send(formData);
        }, false);
    </script>

</body></html>