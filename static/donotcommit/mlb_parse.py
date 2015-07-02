import re

response = "'&mlb_s_delay=120&mlb_s_stamp=0702101651&mlb_s_left1=San%20Francisco%202%20%20%20Miami%201%20(BOT%204TH)&mlb_s_right1_1=%A3%20%20%20%20%20%20%20%20%201%20out&mlb_s_right1_count=1&mlb_s_url1=http://sports.espn.go.com/mlb/gamecast?gameId=350702128&mlb_s_left2=Cleveland%201%20%20%20Tampa%20Bay%202%20(TOP%205TH)&mlb_s_right2_1=%A2%20%20%20%20%20%20%20%20%201%20out&mlb_s_right2_count=1&mlb_s_url2=http://sports.espn.go.com/mlb/gamecast?gameId=350702130&mlb_s_left3=Pittsburgh%200%20%20%20Detroit%200%20(TOP%201ST)&mlb_s_right3_count=0&mlb_s_url3=http://sports.espn.go.com/mlb/gamecast?gameId=350702106&mlb_s_left4=Chicago%20Cubs%200%20%20%20NY%20Mets%200%20(TOP%201ST)&mlb_s_right4_count=0&mlb_s_url4=http://sports.espn.go.com/mlb/gamecast?gameId=350702121&mlb_s_left5=Milwaukee%20at%20Philadelphia%20(6:35%20PM%20ET)&mlb_s_right5_1=Garza%20vs.%20Billingsley&mlb_s_right5_count=1&mlb_s_url5=http://sports.espn.go.com/mlb/scoreboard&mlb_s_left6=Texas%20at%20Baltimore%20(7:05%20PM%20ET)&mlb_s_right6_1=Gallardo%20vs.%20Gausman&mlb_s_right6_count=1&mlb_s_url6=http://sports.espn.go.com/mlb/scoreboard&mlb_s_left7=Boston%20at%20Toronto%20(7:07%20PM%20ET)&mlb_s_right7_1=Miley%20vs.%20Boyd&mlb_s_right7_count=1&mlb_s_url7=http://sports.espn.go.com/mlb/scoreboard&mlb_s_left8=Washington%20at%20Atlanta%20(7:10%20PM%20ET)&mlb_s_right8_1=Scherzer%20vs.%20Banuelos&mlb_s_right8_count=1&mlb_s_url8=http://sports.espn.go.com/mlb/scoreboard&mlb_s_left9=San%20Diego%20at%20St.%20Louis%20(7:15%20PM%20ET)&mlb_s_right9_1=Ross%20vs.%20Cooney&mlb_s_right9_count=1&mlb_s_url9=http://sports.espn.go.com/mlb/scoreboard&mlb_s_left10=Minnesota%20at%20Kansas%20City%20(8:10%20PM%20ET)&mlb_s_right10_1=Gibson%20vs.%20Young&mlb_s_right10_count=1&mlb_s_url10=http://sports.espn.go.com/mlb/scoreboard&mlb_s_left11=Colorado%20at%20Arizona%20(9:40%20PM%20ET)&mlb_s_right11_1=Rusin%20vs.%20Hellickson&mlb_s_right11_count=1&mlb_s_url11=http://sports.espn.go.com/mlb/scoreboard&mlb_s_left12=Seattle%20at%20Oakland%20(10:05%20PM%20ET)&mlb_s_right12_1=Elias%20vs.%20Kazmir&mlb_s_right12_count=1&mlb_s_url12=http://sports.espn.go.com/mlb/scoreboard&mlb_s_count=12&mlb_s_loaded=true'"


raw_info  = response.split(")")
raw = []
for info in raw_info:
  print info
  event = info.split("&mlb_s_left")
  if len(event) > 1 : raw.append(event[1])

for event in raw:
  all = re.match("\d+?=(.*?)\((.*?)$", event)
  result = all.groups()[0].replace("%20", " ")

  if " at " in result:
    teams = result.split(" at ")
    print teams
    info = all.groups()[1].replace("%20", " ")
    print info
  else: 
    m = re.match("(.*?)\s(\d+)\s+(.*?)\s(\d+).*$", result)
    print m.groups()
    info = all.groups()[1]
    print info





 

