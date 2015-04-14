import sys
sys.path.append('./lib')
from soccer_parser import SoccerProvider, SoccerResult


def main():
 provider = SoccerProvider()
 results = provider.fetch_results('http://sports.yahoo.com/soccer//rss.xml')
 print results
 results = provider.fetch_results('test/feed1.xml')
 print results
 results = provider.fetch_results('test/feed2.xml')
 print results


if __name__ == "__main__":
  main()
