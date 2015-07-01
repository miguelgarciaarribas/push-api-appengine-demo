from google.appengine.ext import ndb
from soccer_feed_model import EventDay, SoccerEvent
import soccer_feed_model
import soccer_util

import hashlib

def display_results(day, month, year):
  messages = soccer_feed_model.get_soccer_results(day, month, year)
  scores = []
  for soccer_event in messages:
    m = hashlib.md5()
    m.update(soccer_event.home_team)
    m.update(soccer_event.visitor_team)
    m.update(soccer_util.format_key(day, month, year))
    result = {
      "id" : m.hexdigest(),
      "home_team" : soccer_event.home_team,
      "visitor_team" : soccer_event.visitor_team,
      "home_score" : soccer_event.home_score,
      "visitor_score" : soccer_event.visitor_score,
      "day" : day,
      "month" : month,
      "year" : year

      }
    scores.append(result)
  return { "laliga" : scores  }
