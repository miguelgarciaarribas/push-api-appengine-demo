<!doctype html>
<html><head>
    <title>Test Event</title>
    <meta name="viewport" content="initial-scale=1">
    <style>
    body {
        text-align: center;
    }
    form {
        display: inline-block;
    }
    label {
        display: block;
        text-align: right;
    }
    .result {
        font-style: italic;
    }

    </style>
</head><body>
    <h1>Setup</h1>
    <form method="post">
        <label>Competition
            <input name="competition" value="{{competition}}">
        </label>
        <label>Home Team
            <input name="hometeam" value="{{hometeam}}">
        </label>
        <label>Home Score
            <input type="number" name="homescore"  value="{{homescore}}">
        </label>
        <label>Visitor Team
            <input name="visitorteam"  value="{{visitorteam}}">
        </label>
        <label>Home Score
            <input type="number" name="visitorscore"  value="{{visitorscore}}">
        </label>
        <input type="submit">
    </form>
%if result:
    <p class="result">{{result}}</p>
%end

<input id="send" type=button value="Send Raw Push Message"/>
<p class="result" id="log"> </p>

<script>
 function start() {
   var $ = document.querySelector.bind(document);
   $('#send').addEventListener('click', function(event) {
     event.preventDefault();
     fetch('/test/sendmessage')
         .then(function() {$("#log").textContent = "Message sent";})
         .catch(function() {$("#log").textContent = "Error sending message";} )
   });
 }
 start();
</script>

</body></html>
