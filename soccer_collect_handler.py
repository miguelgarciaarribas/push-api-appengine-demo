from google.appengine.ext import ndb
from soccer_feed_model import EventDay, SoccerEvent
import soccer_feed_model

def display_results(day, month, year):
  messages = soccer_feed_model.get_soccer_results(day, month, year)
  scores = []
  for soccer_event in messages:
    result = {
      "home_team" : soccer_event.home_team,
      "visitor_team" : soccer_event.visitor_team,
      "home_score" : soccer_event.home_score,
      "visitor_score" : soccer_event.visitor_score
      }
    scores.append(result)
  return { "laliga" : scores  }
