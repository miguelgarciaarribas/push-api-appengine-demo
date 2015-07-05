# Base class to parse results from the different sport providers


class SportResult:
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

class SportProvider:
  def __init__(self):
      pass
  def fetch_results(self, feed_url):
      pass
  def _collectResults(self, feed):
      pass
