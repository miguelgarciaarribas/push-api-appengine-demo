from google.appengine.ext import ndb

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
