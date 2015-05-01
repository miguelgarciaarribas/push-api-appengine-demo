import soccer_util


print soccer_util.format_key()
print soccer_util.format_key(2, 1, 2015)
print soccer_util.format_key(20, 12, 2015)

print soccer_util.format_month_day_key("January 1")
print soccer_util.format_month_day_key("April 7")
print soccer_util.format_month_day_key("December 21")

print "Errros"
print soccer_util.format_month_day_key("Dec 27")
print soccer_util.format_month_day_key("Garbage")
print soccer_util.format_month_day_key("May")

