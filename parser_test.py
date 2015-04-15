import sys
sys.path.append('./lib')
from soccer_parser import SoccerProvider, SoccerResult


def main():
  provider = SoccerProvider()
  print "Live Feed"
  results = provider.fetch_results('http://sports.yahoo.com/soccer//rss.xml')
  print results

  print "Test feed 1, itemized"
  results = provider.fetch_results('test/feed1.xml')
  for league in results:
    for result in league:
      print result

  print "Test feed 2, non itemized"
  results = provider.fetch_results('test/feed2.xml')
  print results


if __name__ == "__main__":
  main()
