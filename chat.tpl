<!doctype html>
<html><head>
    <title>Chat App</title>
    <meta name="viewport" content="width=device-width, user-scalable=no">
    <style>
        #login-page {
            transition: height 1s;
        }
        #chat-page {
            transition: opacity 1s;
            opacity: 0.001;
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
    See also <a href="/stock">stocks app</a>.
    <section id="login-page">
        <label>Username: <input type="text" id="username"></label><br>
        <button id="join-button">Join chatroom</button><span id="join-result"></span>
    </section>
    <section id="chat-page">
        <pre id="incoming-messages"></pre>
        <input type="text" id="message">
        <button id="send-button">Send</button><span id="send-result"></span>
    </section>
    <script>
        var $ = document.querySelector.bind(document);

        function setStatus(buttonName, className, text) {
            var result = $('#' + buttonName + '-result');
            result.textContent = " " + text;
            if (!text)
                return;
            result.className = className;
            if (buttonName == 'join' && className == 'fail')
                $('#join-button').disabled = false;
            console.log(buttonName + " " + className + ": " + text);
        }

        if (!('push' in navigator) || !('Notification' in window)) {
            setStatus('join', 'fail',
                      "Your browser does not support push notifications.");
            $('#join-button').disabled = true;
        }

        $('#join-button').addEventListener('click', function() {
            $('#join-button').disabled = true;
            Notification.requestPermission(function(permission) {
                if (permission != 'granted') {
                    setStatus('join', 'fail', 'Permission denied!');
                } else {
                    var SENDER_ID = 'INSERT_SENDER_ID';
                    navigator.push.register(SENDER_ID).then(function(pr) {
                        console.log(pr);
                        sendRegistrationToBackend(pr.pushEndpoint,
                                                  pr.pushRegistrationId);
                    }, function() {
                        setStatus('join', 'fail', "API call unsuccessful!");
                    });
                }
            });
        }, false);

        function sendRegistrationToBackend(endpoint, registrationId) {
            console.log("Sending registration to johnme-gcm.appspot.com...");
            setStatus('join', '', "");

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
                    navigator.push.addEventListener("push", onPush, false);
                    switchToChatPage();
                }
                
            };
            xhr.onerror = xhr.onabort = function() {
                setStatus('join', 'fail', "Failed to send registration ID!");
            };
            xhr.open('POST', '/chat/register');
            xhr.send(formData);
        }

        function switchToChatPage() {
            var lp = $('#login-page');
            var cp = $('#chat-page');
            lp.style.height = lp.getBoundingClientRect().height + 'px';
            lp.style.overflow = 'hidden';
            lp.clientHeight /* force layout */;
            setTimeout(function() {
                // Start transition
                lp.style.height = '0';
                cp.style.opacity = '1';
            }, 0);
        }

        function onPush(evt) {
            console.log(evt);
            var data = evt.data;
            if (!/^chat /.test(data))
                return;
            var usernameAndMessage = data.substring('chat '.length);
            $('#incoming-messages').textContent += "\n" + usernameAndMessage;

            var splits = usernameAndMessage.split(/> (.*)/);
            var username = splits[0].substring(1); // substring(1) removes "<"
            var message = splits[1];

            var notification = new Notification("Chat from " + username, {
                body: message,
                tag: 'chat',
                icon: '/static/chat.png'
            });

            notification.onclick = function() {
                notification.close();
                console.log("Notification clicked.");
                window.focus();
            }
        }

        $('#send-button').addEventListener('click', function() {
            console.log("Sending message to johnme-gcm.appspot.com...");
            setStatus('send', '', "");

            var formData = new FormData();
            formData.append('message',
                "<" + $('#username').value + "> " + $('#message').value);

            var xhr = new XMLHttpRequest();
            xhr.onload = function() {
                if (('' + xhr.status)[0] != '2') {
                    setStatus('send', 'fail', "Server error " + xhr.status
                                              + ": " + xhr.statusText);
                } else {
                    setStatus('send', 'success', "Sent.");
                }
            };
            xhr.onerror = xhr.onabort = function() {
                setStatus('send', 'fail', "Failed to send!");
            };
            xhr.open('POST', '/chat/send');
            xhr.send(formData);

            $('#message').value = "";
        }, false);
    </script>

</body></html>