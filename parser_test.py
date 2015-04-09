import sys
sys.path.append('./lib')
import feedparser
import parser


def main():
 world_soccer = feedparser.parse('http://sports.yahoo.com/soccer//rss.xml')
 parser.getSoccerResults(world_soccer)


if __name__ == "__main__":
  main()
