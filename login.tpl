<!doctype html>
<html><head>
    <title>ChatApp</title>
    <meta name="viewport" content="width=device-width, user-scalable=no">
    <style>
        body {
            display: flex;
            flex-direction: column;
        }
        #title {
            text-align: center;
        }
        #login {
            flex: auto;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-self: center;
            align-items: flex-start;
        }
    </style>
</head><body>
    <h1 id="title">ChatApp</h1>
    <form id="login" method="post">
        <input type="hidden" name="endpoint">
        <input type="hidden" name="registration_id">
        <label>Username: <input type="text" name="username"></label>
        <button id="join_button">Join chatroom</button>
    </form>
    <script>
        var $ = document.querySelector;

        if (!("push" in navigator)) {
            $('#login').innerHTML = 
        }

        $('#join_button').addEventListener("click", function() {
            $('#join_button').disabled = true;
            navigator.push.register("INSERT_SENDER_ID").then(function(pushRegistration) {
                console.log(pushRegistration);

            }, function() {
                console.log("catch", arguments);
            })
        }, false);
    </script>
</body></html>

# promise = navigator.push.register("INSERT_SENDER_ID");

# promise.then(function() { console.log("then", arguments); }, function() { console.log("catch", arguments); });
I/chromium(16744): [INFO:CONSOLE(2)] "then", source:  (2)
PushRegistration
- channelName: "INSERT_SENDER_ID"
- pushEndpoint: "test_endpoint"
- pushRegistrationId: "APA91bFyW-KcpOb1aDS8OvK8jhEu5AXw50pGGafazf9IFyXjw9r-j7YHmXgeLw-O-RAjjzKE0fopt5gEbfmYl_tbULZwup9KNavQfxn8lmAc7iWVZ2zLv63gZ9dz4F2EK49tCozn0BPn9kkTDVlFOWgom9IPUm8rJ7k74aZcwlhZo-FwOKMzCIE"