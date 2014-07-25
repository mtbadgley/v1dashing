require 'HTTParty'
require 'json'
require 'date'

$v1user = "admin"
$v1pass = "admin"
$auth = {:username => $v1user, :password => $v1pass}
$v1queryurl = "http://win8/VersionOne/query.v1"

$title = " Burndown"

def GetTotalOpen(iteration,asofdate)
	remainingworkquery = '[{
							"from": "Timebox",
							"select": [ "Workitems.ToDo.@Sum" ],
							"filter": [ "Name=\'' + iteration + '\'" ],
							"asof": "' + asofdate + 'T23:59:59' + '"
							}]'

	result = HTTParty.get($v1queryurl, :body => remainingworkquery, :basic_auth => $auth, :output => 'json')
	remainingwork = result[0]
	if remainingwork.count > 0 
		return remainingwork[0]["Workitems.ToDo.@Sum"]
	else
		return 0
	end
end

def GetDatesOfSprint(begindate,enddate)
	datesofsprint = Array.new
	Date.parse(begindate).upto(Date.parse(enddate)) do |asofdate|
		datesofsprint.push asofdate.to_s
	end
	return datesofsprint
end

def GetBurndownPoints()
	query = '[{
				"from": "Timebox",
				"select": [ "BeginDate", "EndDate", "Name" ],
				"filter": [ "AssetState=\'Active\'", 
							"Schedule.ScheduledScopes.Name=\'Call Center (Product)\'" ],
				"sort": "-EndDate"
	}]'

	queryresult = HTTParty.get($v1queryurl, :body => query, :basic_auth => $auth, :output => 'json')

	timeboxes = queryresult[0]

	# Use the most recent active timebox
	timboxoid = timeboxes[0]["_oid"]
	timebox = timeboxes[0]["Name"]
	timeboxbegin = timeboxes[0]["BeginDate"][0..9]
	timeboxend = timeboxes[0]["EndDate"][0..9]

	$title = timebox

	dates = GetDatesOfSprint(timeboxbegin,timeboxend)

	points = ""

	i = 1

	dates.each do |dayofwork|
		if Date.parse(dayofwork) <= Date.today
			todo = GetTotalOpen(timebox,dayofwork)
		else
			todo = "null"
		end
		point = '{ "x": ' + i.to_s + ', "y": ' + todo + ' },'	
		points += point
		i += 1
	end

	if points.length > 0
		points = "[ " + points[0..-2] + " ]"
	end 
	
	return points
end

SCHEDULER.every '20s', first_in: 0 do |job|
  data = GetBurndownPoints()

  datax = JSON.parse(data)
  send_event('burndownchart', points: datax, title: $title)
end