<!doctype html>
<html><head>
    <title>Soccer Results</title>
    <meta name="viewport" content="width=device-width, user-scalable=no">
    <link rel="manifest" href="/manifest.json">
    <link rel="icon" type="image/png" href="/static/hangouts.png" sizes="42x42">
    <link href="/static/roboto.css" rel="stylesheet" type="text/css">
    <link href="/static/soccer_home.css" rel="stylesheet" type="text/css">

    <!-- Polymer includes -->
    <link rel="import" href="/static/components/core/components/core-toolbar/core-toolbar.html">
    <link rel="import" href="/static/components/soccer/soccer-result.html">
    <link rel="import" href="/static/components/soccer/soccer-results.html">
    <link rel="import" href="/static/components/soccer/sports-tabs.html">

    <script src="/static/display/main.js"> </script>
    <script src="/static/localstore/soccer_access.js"> </script>
    <script src="/static/localstore/soccer_db.js"> </script>
</head>

<body unresolved>
  <core-toolbar>
    <sports-tabs id="tabs" self-end>
    </sports-tabs>
  </core-toolbar>

  <div id="result-elements"> </div>
  <input id="subscribe" type=button value="Subscribe to push!"/>
  <input id="refresh" type=button value="Refresh IndexDB"/>
  <a href ="/display/hello.html"> SW CHECK </a>
  <p id="log"> </p>

<script>
  window.addEventListener('load', function() {
      start();
  });
</script>


</body></html>
