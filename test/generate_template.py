# A small generator of feeds with todays date
import sys
sys.path.append('../')

import soccer_util
def main():
    input = open('feed1_template.xml', 'r')
    output = open('feed1_out.xml', 'w')
    template = input.read()
    date = soccer_util.create_test_date()
    print "Generated feed for" , date
    result = template.replace("{{DATE}}", date)
    output.write(result)

if __name__ == "__main__":
    main()
