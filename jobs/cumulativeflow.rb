require 'HTTParty'
require 'json'
require 'date'

$v1user = "admin"
$v1pass = "admin"
$auth = {:username => $v1user, :password => $v1pass}
$v1queryurl = "http://win8/VersionOne/query.v1"

$timeboxoid = ""
$timeboxname = ""

def GetDatesOfSprint(begindate,enddate)
	datesofsprint = Array.new
	Date.parse(begindate).upto(Date.parse(enddate)) do |asofdate|
		datesofsprint.push asofdate.to_s
	end
	return datesofsprint
end

def GetCurrentSprint(parentprojectid)
	query = '[{
			"from": "Timebox",
			"select": [ "BeginDate", "EndDate", "Name" ],
			"filter": [ "AssetState=\'Active\'", 
						"Schedule.ScheduledScopes.ID=\'' + parentprojectid + '\'" ],
			"sort": "-EndDate"
			}]'

	queryresult = HTTParty.get($v1queryurl, :body => query, :basic_auth => $auth, :output => 'json')

	timeboxes = queryresult[0]

	# Use the most recent active timebox
	$timeboxoid = timeboxes[0]["_oid"]
	$timeboxname = timeboxes[0]["Name"]
	timeboxbegin = timeboxes[0]["BeginDate"][0..9]
	timeboxend = timeboxes[0]["EndDate"][0..9]

	dates = GetDatesOfSprint(timeboxbegin,timeboxend)

	return dates
end

def BuildQuery(originalquery,timeboxoid,parentprojectoid,statusname,asofdate)
	newquery = '{ "from": "Timebox",
				  "select": [ "Workitems:PrimaryWorkitem[AssetState=\'64\',\'128\';Status.Name=\'' + statusname + '\';Scope.ParentMeAndUp=\'' + parentprojectoid + '\'].Estimate.@Sum" ],
				  "filter": [ "ID=\'' + timeboxoid + '\'" ],
				  "asof": "' + asofdate + 'T23:59:59" }'

	if originalquery.length == 0
		builtquery = newquery
	else		
		builtquery = "#{originalquery},#{newquery}"  
	end

	return builtquery
end

def GetSeries(timeboxoid,parentprojectoid,statusname,dates)

	query = ""
	dates.each do |asof|
		query = BuildQuery(query,timeboxoid,parentprojectoid,statusname,asof)
	end
	query = "[#{query}]"

	queryresult = HTTParty.get($v1queryurl, :body => query, :basic_auth => $auth, :output => 'json')

	columnkey = "Workitems:PrimaryWorkitem[AssetState='64','128';Status.Name='#{statusname}';Scope.ParentMeAndUp='#{parentprojectoid}'].Estimate.@Sum"
	series = ""
	seriespoints = ""
	if queryresult.length > 0
		i = 1
		queryresult.each do |result|
			value = result[0][columnkey]
			if value == nil 
				value = 0
			end
			if Date.parse(dates[i-1]) > Date.today
				value = "null"
			end
			point = '{ "x": ' + i.to_s + ', "y": ' + value.to_s + ' },'
			seriespoints += point
			i += 1
		end
		if seriespoints.length > 0
			seriespoints = "[ " + seriespoints[0..-2] + " ]"
		end 
		if statusname.length == 0
			statusname = "(none)"
		end
		series = '{ "name": "' + statusname + '", "data": ' + seriespoints + '},'
	end

	return series
end

def GetCumulativeFlowData(parentprojectoid)

	dates = GetCurrentSprint(parentprojectoid)

	query = '[{
				"from": "StoryStatus",
				"select": [ "Name" ],
				"filter": [ "SelectedInSchemes.Scopes.ParentMeAndUp=\'' + parentprojectoid + '\'" ],
				"sort": "-Order"
			}]'

	queryresult = HTTParty.get($v1queryurl, :body => query, :basic_auth => $auth, :output => 'json')

	statuses = queryresult[0]

	chartseries = ""

	if statuses.length > 0
		statuses.each do |status|
			statusname = status["Name"]
			chartseries += GetSeries($timeboxoid,parentprojectoid,statusname,dates)
		end
		chartseries += GetSeries($timeboxoid,parentprojectoid,"",dates)
	end
	if chartseries.length > 0
		chartseries = "[ " + chartseries[0..-2] + " ]"
	end 
	return chartseries
end


SCHEDULER.every '20s', first_in: 0 do |job|
	data = GetCumulativeFlowData("Scope:1093")
	datax = JSON.parse(data)
	send_event('cumulativeflow', series: datax )
end