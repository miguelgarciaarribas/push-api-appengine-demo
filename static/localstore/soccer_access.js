// Methods that deal with retrieving and storing events

// TODO(miguelg): Delete events from way in the past for perfomance
function _cacheEvents(events, callback) {
  var i = 0;
  while (i < events.length) {
    // TODO: Stop forcing "La Liga"
    soccerDB.createEvent(
        "La Liga", events[i].id, events[i].home_team, events[i].home_score, events[i].visitor_team,
        events[i].visitor_score, events[i].day, events[i].month, events[i].year, function(event) {
          callback(event)
        });
    i++;
  }
}

// Fetch scores related messages
function _fetchScores(day, month, year) {
  if (!!fetch) {
    var promise = new Promise(function(resolve, reject) {
      fetch("/collect/soccer?day=" + day +
          "&month=" + month +
          "&year=" + year)
          .then(function(response) {
            response.json().then(function(data) {
              resolve(data);
            });
          }).catch(function(err) {reject("Error fetching " + err)});
    })
    return promise;
  }
  var promise = new Promise(function(resolve, reject) {
    var req = new XMLHttpRequest();
    req.open("GET", "/collect/soccer?day=" + day +
              "&month=" + month +
              "&year=" + year);
    req.onload = function() {
      if (('' + req.status)[0] != '2') {
        reject("Error");
        return;
      }

      var results = JSON.parse(req.responseText);
      resolve(results);
    };
    req.send();
  });
  return promise;
}

function fetchAndStore(day, month, year, callback) {
    _fetchScores(day, month, year).then(function(result) {
      // TODO stop counting only "laliga" entries
      var events = result["laliga"]
      _cacheEvents(events, callback);
   }, function(err) {
        console.log("Error " + err);
    });
}
