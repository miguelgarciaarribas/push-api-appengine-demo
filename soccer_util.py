import datetime

_months = ["January", "February", "March", "April", "May", "June",
           "July", "August", "September", "October", "November", "December"]

def format_key(day=datetime.datetime.now().day,
               month=datetime.datetime.now().month,
               year=datetime.datetime.now().year):
    if (day == -1 or month == -1 or year == -1):
      return ""
    return str(day).zfill(2) + "/" + str(month).zfill(2) + "/" + str(year)

def extract_date(date):
  """
  Return a date from a parsed soccer feed

  returned as a triple (day, month, year) or None if unable to parse it.
  """
  try:
    month,day = date.split(" ")
    if month in _months:
      return (int(day), _months.index(month) + 1, datetime.datetime.now().year)
    return None
  except: return None

def create_test_date():
  month = _months[datetime.datetime.now().month -1]
  day = datetime.datetime.now().day
  return month + " " + str(day)
