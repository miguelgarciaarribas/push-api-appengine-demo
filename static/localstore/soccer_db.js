var soccerDB = (function() {
  var eventDB = {};
  var datastore = null;

  /**
   * Open a connection to the datastore.
  */
  eventDB.open = function(callback) {
    // Database version.
    var version = 2;

    // Open a connection to the datastore.
    var request = indexedDB.open('soccer_events', version);

    // Handle datastore upgrades.
    request.onupgradeneeded = function(e) {
      var db = e.target.result;

      e.target.transaction.onerror = eventDB.onerror;

      // Delete the old datastore.
      if (db.objectStoreNames.contains('soccer_event')) {
        db.deleteObjectStore('soccer_event');
      }

      // Create a new datastore.
      var store = db.createObjectStore('soccer_event', {
        keyPath: 'id'
      });
    };

    // Handle successful datastore access.
    request.onsuccess = function(e) {
      // Get a reference to the DB.
      datastore = e.target.result;

      // Execute the callback.
      callback();
    };

    // Handle errors when opening the datastore.
    request.onerror = eventDB.onerror;
  };

  /**
   * Fetch all of the events in the datastore.
  */
  eventDB.fetchEvents = function(callback) {
    var db = datastore;
    var transaction = db.transaction(['soccer_event'], 'readonly');
    var objStore = transaction.objectStore('soccer_event');

    var keyRange = IDBKeyRange.lowerBound(0);
    var cursorRequest = objStore.openCursor(keyRange);

    var events = [];

    transaction.oncomplete = function(e) {
      // Execute the callback function.
      callback(events);
    };

    cursorRequest.onsuccess = function(e) {
      var result = e.target.result;

      if (!!result == false) {
        return;
      }

      events.push(result.value);

      result.continue();
    };

    cursorRequest.onerror = eventDB.onerror;
  };


  /**
   * Create a new event.
  */
  eventDB.createEvent = function(league, id, home_team, home_score, visitor_team, visitor_score,
                                 day, month, year, callback) {
    // Get a reference to the db.
    var db = datastore;

    // Initiate a new transaction.
    var transaction = db.transaction(['soccer_event'], 'readwrite');

    // Get the datastore.
    var objStore = transaction.objectStore('soccer_event');

    // Create an object for the event item.
    var event = {
      'league' : league,
      'home_team' : home_team,
      'home_score' : home_score,
      'visitor_team' : visitor_team,
      'visitor_score' : visitor_score,
      'day' : day,
      'month' : month,
      'year' : year,
      'id' : id
    };

    // Create the datastore request.
    // this will fail if the object exits already.
    var request = objStore.add(event);

    // Handle a successful datastore put.
    request.onsuccess = function(e) {
      // Execute the callback function.
      callback(event);
    };

    // Handle errors.
    request.onerror = eventDB.onerror;
  };


  /**
   * Delete an event.
  */
  eventDB.deleteEvent = function(id, callback) {
    var db = datastore;
    var transaction = db.transaction(['soccer_event'], 'readwrite');
    var objStore = transaction.objectStore('soccer_event');

    var request = objStore.delete(id);

    request.onsuccess = function(e) {
      callback();
    }

    request.onerror = function(e) {
      console.log("Unable to delete event" + e);
    }
  };


  // Export the tDB object.
  return eventDB;
}());
