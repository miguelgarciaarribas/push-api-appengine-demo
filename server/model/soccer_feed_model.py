from google.appengine.ext import ndb

import soccer_util


class EventDay(ndb.Model):
  day = ndb.IntegerProperty(required=True)
  month = ndb.IntegerProperty(required=True)
  year = ndb.IntegerProperty(required=True)

class SoccerEvent(ndb.Model):
  #date = ndb.DateProperty(auto_now_add=True)  # Need to set this manually
  league = ndb.StringProperty(required=True)
  home_team = ndb.StringProperty(required=True)
  visitor_team = ndb.StringProperty(required=True)
  home_score = ndb.IntegerProperty(required=True, indexed=False)
  visitor_score = ndb.IntegerProperty(required=True, indexed=False)


def get_soccer_results(day, month, year):
    MAX_RESULTS = 30
    date = soccer_util.format_key(day, month, year)
    event_day_key  = ndb.Key(EventDay, date)
    return SoccerEvent.query(ancestor=event_day_key).fetch(MAX_RESULTS)
