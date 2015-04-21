from google.appengine.ext import ndb
from soccer_feed_model import EventDay, SoccerEvent

def display_results(day, month, year):
  event_day_key  = ndb.Key(EventDay, "20/04/2015")
  messages = SoccerEvent.query(ancestor=event_day_key).fetch(20)
  scores = []
  for soccer_event in messages:
    result = {
      "home_team" : soccer_event.home_team,
      "visitor_team" : soccer_event.visitor_team,
      "home_score" : soccer_event.home_score,
      "visitor_score" : soccer_event.visitor_score
      }
    scores.append(result)
  return { "scores" : scores }
