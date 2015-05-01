import datetime

_months = ["January", "February", "March", "April", "May", "June",
           "July", "August", "September", "October", "November", "December"]

def format_key(day=datetime.datetime.now().day,
               month=datetime.datetime.now().month,
               year=datetime.datetime.now().year):
    if (day == -1 or month == -1 or year == -1):
      return ""
    return str(day).zfill(2) + "/" + str(month).zfill(2) + "/" + str(year)

def format_month_day_key(date):
  try:
    month,day = date.split(" ")
    if month in _months:
      return format_key(day, _months.index(month) + 1)
    return ""
  except: return ""



