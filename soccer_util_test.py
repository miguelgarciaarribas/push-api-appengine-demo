import soccer_util

print "format_key:"
print soccer_util.format_key()
print soccer_util.format_key(2, 1, 2015)
print soccer_util.format_key(20, 12, 2015)

print soccer_util.extract_date("January 1")
print soccer_util.extract_date("April 7")
print soccer_util.extract_date("December 21")

print "create_test_date:"
print soccer_util.create_test_date()


print "Expected Erros (None):"
print soccer_util.extract_date("Dec 27")
print soccer_util.extract_date("Garbage")
print soccer_util.extract_date("May")
