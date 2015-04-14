from google.appengine.ext import ndb
from soccer_parser import SoccerProvider, SoccerResult

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

def soccer_feed_request():
  provider = SoccerProvider()
  results = provider.fetch_results('http://sports.yahoo.com/soccer//rss.xml')

  for result in results:
    print result.league()
    # event_day_key  = ndb.Key(EventDay, "13/04/2015")
    # event = SoccerEvent(parent=event_day_key)
    # event.league = result.league
    # event.home_team = result.home_team
    # event.visitor_team = result.visitor_team
    # event.home_score = result.home_score
    # event.visitor_score = result.visitor_score
    # event.put()
    # print event
  return results


if __name__ == "__main__":
  main()
