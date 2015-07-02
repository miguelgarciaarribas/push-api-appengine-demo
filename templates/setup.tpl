<!doctype html>
<html><head>
    <title>Setup</title>
    <meta name="viewport" content="initial-scale=1">
    <style>
    body {
        text-align: center;
    }
%if result:
    .result {
        font-style: italic;
    }
%end
    form {
        display: inline-block;
    }
    label {
        display: block;
        text-align: right;
    }
    </style>
</head><body>
    <h1>Setup</h1>
%if result:
    <p class="result">{{result}}</p>
%end
    <form method="post">
        <label>GCM endpoint
            <input name="endpoint" value="{{endpoint}}">
        </label>
        <label>GCM sender ID
            <input name="sender_id" value="{{sender_id}}">
        </label>
        <label>GCM API key
            <input name="api_key" value="{{api_key}}">
        </label>
        <input type="submit">
    </form>
</body></html>