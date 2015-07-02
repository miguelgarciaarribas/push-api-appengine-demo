import sys
sys.path.append('../../lib')
import feedparser
import re

LA_LIGA_SCORES_KEY = "Results and standings from the La Liga matches"
DATE_SCORES_RE = "(\w+?\s\d+)?\s?(.*)"
TEAM_RESULT_RE = "\s(\d+?)(\s|$)"


class SoccerResult:
  def __init__(self, date, league, home_team, visitor_team, home_score, visitor_score):
    self.date = date
    self.league = league
    self.home_team = home_team
    self.visitor_team = visitor_team
    self.home_score = home_score
    self.visitor_score = visitor_score
  def __repr__(self):
    return "(" + self.league + "/" + self.date + ")" + self.home_team + ":" \
        + self.home_score + " - " + self.visitor_team + ":" + self.visitor_score


class SoccerProvider:
  def fetch_results(self, feed_url):
    world_soccer_feed = feedparser.parse(feed_url)
    return self._collect_results(world_soccer_feed)

  def _collect_results(self, world_soccer_feed):
    results = []
    for entry in world_soccer_feed.entries:
      if "Infostrada" and LA_LIGA_SCORES_KEY in entry.description: # Probably change this to search for title.
        results.append(self._getLaLigaResults(entry.description))
    return results

  def _getLaLigaResults(self, world_soccer):
    soccer_results = []
    pieces = world_soccer.split(', ')
    last_piece = pieces[-1].split(' Standings ')[0]
    pieces = pieces[1:-1]
    pieces.append(last_piece)
    results = []
    for piece in pieces:
      match = re.search(DATE_SCORES_RE, piece)
      results.append((match.group(1), match.group(2)))
    for result in results:
      team_results = re.split(TEAM_RESULT_RE, result[1])
      date = result[0]
      league = "La Liga"
      home_team = ""
      home_score = -1
      visitor_team = ""
      visitor_score = -1

      for team_result in filter(lambda x : x != " ", team_results):
        if not home_team:
          home_team = team_result
        elif home_score == -1:
          home_score = team_result
        elif not visitor_team:
          visitor_team = team_result
        elif visitor_score == -1:
          visitor_score = team_result

        if (home_team and home_score != -1 and visitor_team and visitor_score != -1):
          soccer_results.append(SoccerResult(date, league, home_team, visitor_team,
                                             home_score, visitor_score))
          home_team = ""
          visitor_team = ""
          home_score = -1
          visitor_score = -1
    return soccer_results
