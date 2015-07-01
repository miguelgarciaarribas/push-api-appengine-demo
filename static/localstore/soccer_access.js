// Methods that deal with retrieving and storing events

// TODO(miguelg): Delete events from way in the past for perfomance
function _cacheEvents(events) {
  var i = 0;
  while (i < events.length) {
    soccerDB.createEvent(
        "La Liga", events[i].id, events[i].home_team, events[i].home_score, events[i].visitor_team,
        events[i].visitor_score, events[i].day, events[i].month, events[i].year, function(event) {
          // TODO: Refresh when an event for the current viewing day happens.
          // Or that they are all for the same day.
          if (i == events.length- 1) {
            console.log("Last Element saved should probably trigger a refresh." + event);
          }
        });
    i++;
  }
}

// Fetch scores related messages
function _fetchScores(day, month, year) {
  var promise = new Promise(function(resolve, reject) {
    var req = new XMLHttpRequest();
    var today = new Date()
    req.open("GET", "/collect/soccer?day=" + day +
              "&month=" + month +
              "&year=" + year);
    req.onload = function() {
      if (('' + req.status)[0] != '2') {
        reject("Error");
        return;
      }
      console.log(req.responseText);
      var results = JSON.parse(req.responseText);
      resolve(results);
    };
    req.send();
  });
  return promise;
}

function fetchAndStore(day, month, year) {
    _fetchScores(day, month, year).then(function(result) {
      // TODO stop counting only "laliga" entries
      var events = result["laliga"]
      _cacheEvents(events);
   }, function(err) {
        console.log("Error " + err);
    });
}
