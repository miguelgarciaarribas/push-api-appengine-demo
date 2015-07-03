import sys
sys.path.append('../lib')
sys.path.append('../server/parser')
from mlb_parser import *

def main():
  provider = MlbProvider()
  print "Live Feed"
  results = provider.fetch_results('http://sports.espn.go.com/mlb/bottomline/scores')
  print results

  # print "Test feed 1, itemized"
  # results = provider.fetch_results('feed1.xml')
  # for league in results:
  #   for result in league:
  #     print result

  # print "Test feed 2, non itemized"
  # results = provider.fetch_results('feed2.xml')
  # print results


if __name__ == "__main__":
  main()
