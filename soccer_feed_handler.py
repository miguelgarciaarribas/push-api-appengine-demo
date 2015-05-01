from google.appengine.ext import ndb
from soccer_parser import SoccerProvider, SoccerResult
from soccer_feed_model import EventDay, SoccerEvent
import soccer_util

def soccer_feed_request():
  provider = SoccerProvider()
  results = provider.fetch_results('http://sports.yahoo.com/soccer/rss.xml')

  for league in results:
    for result in league:
      date = soccer_util.format_month_day_key(result.date)
      if date == "":
        continue
      event_day_key  = ndb.Key(EventDay, date)
      event = SoccerEvent(parent=event_day_key)
      event.league = result.league
      event.home_team = result.home_team
      event.visitor_team = result.visitor_team
      event.home_score = int(result.home_score)
      event.visitor_score = int(result.visitor_score)
      event.put()
      print event
    return results


if __name__ == "__main__":
  main()
