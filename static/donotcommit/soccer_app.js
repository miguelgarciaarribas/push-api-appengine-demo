window.onload = function() {
  // Display events.
  soccerDB.open(refreshEvents);

  // Get references to the form elements.
  var newEventForm = document.getElementById('new-todo-form');
  var liga_field = document.getElementById('liga');
  var home_team_field = document.getElementById('hometeam');
  var home_result_field = document.getElementById('homeresult');

  // Handle new item form submissions.
  newEventForm.onsubmit = function() {
    // Get the text.
    var liga = liga_field.value;
    var home_team = home_team_field.value;
    var home_score = home_result_field.value;

    // Check to make sure the text is not blank (or just spaces).
    if (liga.replace(/ /g,'') != '') {
      // Create the event.
      soccerDB.createEvent(liga, home_team, home_score, 'Barcelona', 0, function(event) {
        refreshEvents();
      });
    }

    // Reset the input field.
    newTodoInput.value = '';

    // Don't send the form.
    // TODO Try changing this to add event listener with prevent default
    return false;
  };
};

// Update the list of todo items.
function refreshEvents() {
  soccerDB.fetchEvents(function(events) {
    var eventList = document.getElementById('todo-items');
    eventList.innerHTML = '';

    for(var i = 0; i < events.length; i++) {
      // Read the events backwards (most recent first).
      var event = events[(events.length - 1 - i)];

      var li = document.createElement('li');
      li.id = 'todo-' + event.timestamp;
      var checkbox = document.createElement('input');
      checkbox.type = "checkbox";
      checkbox.className = "todo-checkbox";
      checkbox.setAttribute("data-id", event.timestamp);

      li.appendChild(checkbox);

      var span = document.createElement('span');
      span.innerHTML = event.league + ': ' + event.home_team +
          " " + event.home_score + "-" + event.visitor_team + " " + event.visitor_score;

      li.appendChild(span);

      eventList.appendChild(li);

      // Setup an event listener for the checkbox.
      checkbox.addEventListener('click', function(e) {
        var id = parseInt(e.target.getAttribute('data-id'));

        soccerDB.deleteEvent(id, refreshEvents);
      });
    }

  });
}
