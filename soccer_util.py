import datetime

def format_today_key():
  day = datetime.datetime.now().day
  month = datetime.datetime.now().month
  year = datetime.datetime.now().year
  return format_key(day, month, year)

def format_key(day, month, year):
    return str(day).zfill(2) + "/" + str(month).zfill(2) + "/" + str(year)
