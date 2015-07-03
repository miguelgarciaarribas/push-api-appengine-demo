import re
import urllib2

# class MlbResult:
#   def __init__(self, date, league, home_team, visitor_team, home_score, visitor_score):
#     self.date = date
#     self.league = league
#     self.home_team = home_team
#     self.visitor_team = visitor_team
#     self.home_score = home_score
#     self.visitor_score = visitor_score
#   def __repr__(self):
#     return "(" + self.league + "/" + self.date + ")" + self.home_team + ":" \
#         + self.home_score + " - " + self.visitor_team + ":" + self.visitor_score


class MlbProvider:
  def fetch_results(self, url): # http://sports.espn.go.com/mlb/bottomline/scores
    response = urllib2.urlopen(url)
    return self._collect_results(response.read())

  def _collect_results(self, raw):
      if not raw:
          return
      raw_info  = raw.split(")")
      raw = []
      for info in raw_info:
          print info
          event = info.split("&mlb_s_left")
          if len(event) > 1 : raw.append(event[1])

      for event in raw:
        all = re.match("\d+?=\^?(.*?)\((.*?)$", event)
        result = all.groups()[0].replace("%20", " ")

        if " at " in result:
          teams = result.split(" at ")
          print teams
          info = all.groups()[1].replace("%20", " ")
          print info
        else: 
          m = re.match("(.*?)\s(\d+)\s+(.*?)\s(\d+).*$", result)
          print m.groups()
          info = all.groups()[1]
          print info
