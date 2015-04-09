import re

LA_LIGA_SCORES_KEY = "Results and standings from the La Liga matches"
#LA_LIGA_SUMMARIES_KEY = "Summaries from the La Liga matches"
#LA_LIGA_TOP_SCORERS = "Top scorers of the La Liga"

DATE_SCORES_RE = "(\w+?\s\d+)?\s?(.*)"
TEAM_RESULT_RE = "\s(\d+?)(\s|$)"


class SoccerResult:
  def __init__(self, league, home_team, visitor_team, home_score, visitor_score):
    self.league = league
    self.home_team = home_team
    self.visitor_team = visitor_team
    self.home_score = home_score
    self.visitor_score = visitor_score
  def __repr__(self):
    return "(" + self.league + ")" + self.home_team + ":" + self.home_score + " - " \
        + self.visitor_team + ":" + self.visitor_score


def getSoccerResults(world_soccer):
  for entry in world_soccer.entries:
    if "Infostrada" and LA_LIGA_SCORES_KEY in entry.description: # Probably change this to search for title.
      soccer_results = []
      pieces = entry.description.split(', ')
      last_piece = pieces[-1].split(' Standings ')[0]
      pieces = pieces[1:-1]
      pieces.append(last_piece)
      results = []
      for piece in pieces:
        match = re.search(DATE_SCORES_RE, piece)
        results.append(match.group(2))
      for result in results:
        team_results = re.split(TEAM_RESULT_RE, result)
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
            soccer_results.append(SoccerResult(league, home_team, visitor_team, home_score, visitor_score))
            home_team = ""
            visitor_team = ""
            home_score = -1
            visitor_score = -1
      print soccer_results
      print entry.description
