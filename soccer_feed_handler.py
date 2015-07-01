from google.appengine.ext import ndb
import logging
from soccer_parser import SoccerProvider, SoccerResult
from soccer_feed_model import EventDay, SoccerEvent
import soccer_feed_model
import soccer_util

import datetime

def soccer_feed_request(callback):
  provider = SoccerProvider()
  #Use 'test/feed1_out.xml' for testing
  feed_results = provider.fetch_results('test/feed2_out.xml')   #('http://sports.yahoo.com/soccer/rss.xml')
  callback(_merge_feed_results(feed_results))
  return feed_results

# Just meant for testing
def merge_test_entry(league, hometeam, homescore, visitorteam, visitorscore, callback):
  test_result = SoccerResult(soccer_util.create_test_date(),
                             league, hometeam, visitorteam, homescore, visitorscore)
  callback(_merge_feed_results([[test_result]]))

def _merge_feed_results(feed_results):
  existing_results = {}
  new_results = set()
  # Collect existing results for matches in the same day
  for event_date in feed_results:
    for result in event_date:
      date = soccer_util.extract_date(result.date)
      if date:
        day, month, year = date
        if date not in existing_results:
          existing_results[soccer_util.format_key(day, month, year)] = \
              soccer_feed_model.get_soccer_results(day, month, year)
  # Collect results from the feed
  for league in feed_results:
    for result in event_date:
      if merge_result(result, existing_results):
        new_results.add(result)
  return new_results

def merge_result(result, existing_results):
   date = soccer_util.extract_date(result.date)
   if date == None:
     return
   key = soccer_util.format_key(date[0], date[1], date[2])
   if existing_results.has_key(key):
     for existing_result in existing_results[key]:
       # TODO: need to replace the result from the feed since the score
       # can more recent.
       # For now we just skip it because it's easier
       if (existing_result.home_team == result.home_team and
            existing_result.visitor_team == result.visitor_team):
         if (existing_result.home_score != result.home_score or
             existing_result.visitor_score != result.visitor_score):
           logging.warning("Newer result will not be applied.")
         return None
   _commit_result(result)
   return result

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
