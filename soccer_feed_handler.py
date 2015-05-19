from google.appengine.ext import ndb
from soccer_parser import SoccerProvider, SoccerResult
from soccer_feed_model import EventDay, SoccerEvent
import soccer_feed_model
import soccer_util

import datetime

def soccer_feed_request():
  provider = SoccerProvider()
  feed_results = provider.fetch_results('http://sports.yahoo.com/soccer/rss.xml')
  _merge_feed_results(feed_results)
  return feed_results

# Just meant for testing
def merge_test_entry(league, hometeam, homescore, visitorteam, visitorscore):
  test_result = SoccerResult(soccer_util.create_test_date(),
                             league, hometeam, visitorteam, homescore, visitorscore)
  _merge_feed_results([[test_result]])

def _merge_feed_results(feed_results):
  existing_results = {}
  # Collect existing results for matches in the same day
  for league in feed_results:
    for result in league:
      date = soccer_util.extract_date(result.date)
      if date is not None:
        day, month, year = date
        existing_results[soccer_util.format_key(day, month, year)] = \
           soccer_feed_model.get_soccer_results(day, month, year)

  # Collect results from the feed
  for league in feed_results:
    for result in league:
      merge_result(result, existing_results)
    return feed_results


def merge_result(result, existing_results):
   date = soccer_util.extract_date(result.date)
   if date == None:
     return
   key = soccer_util.format_key(date[0], date[1], date[2])
   if existing_results.has_key(key):
     for existing_result in existing_results[key]:
       # It's probably better to replace the result from the feed since the score
       # might more recent.
       # For now we just skip it because it's easier
       if (existing_result.home_team == result.home_team and
            existing_result.visitor_team == result.visitor_team):
         return
   _commit_result(result)

def _commit_result(result):
  date = soccer_util.extract_date(result.date)
  if date == None:
    return
  event_day_key  = ndb.Key(EventDay, soccer_util.format_key(date[0], date[1], date[2]))
  event = SoccerEvent(parent=event_day_key)
  event.league = result.league
  event.home_team = result.home_team
  event.visitor_team = result.visitor_team
  event.home_score = int(result.home_score)
  event.visitor_score = int(result.visitor_score)
  event.put()
