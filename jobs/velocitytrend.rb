require 'HTTParty'
require 'json'
require 'date'

$v1user = "admin"
$v1pass = "admin"
$auth = {:username => $v1user, :password => $v1pass}
$v1queryurl = "http://win8/VersionOne/query.v1"

$title = " Burndown"

def GetVelocityTrend(parentprojectoid,teamoid,numpasttimeboxes)

	columnkey = "Workitems:PrimaryWorkitem.Estimate.@Sum"
	if teamoid.length > 0
		columnkey = "Workitems:PrimaryWorkitem[Team='#{teamoid}'].Estimate.@Sum"
	end
	velocitytrendquery = '[{
							"from": "Timebox",
							"select": [ "' + columnkey + '" ],
							"filter": [ "AssetState=\'Closed\'", 
										"Schedule.ScheduledScopes.ID=\'' + parentprojectoid + '\'" ],
							"sort": "-EndDate"
							}]'

	result = HTTParty.get($v1queryurl, :body => velocitytrendquery, :basic_auth => $auth, :output => 'json')
	velocitytrend = result[0]
	points = ""
	i = 1

	velocitytrend.take(numpasttimeboxes).each do |velocity|
		value = velocity[columnkey]
		point = '{ "x": ' + i.to_s + ', "y": ' + value.to_s + ' },'	
		points += point
		i += 1
	end

	if points.length > 0
		points = "[ " + points[0..-2] + " ]"
	end 
	
	return points
end

SCHEDULER.every '1m', first_in: 0 do |job|
  data = GetVelocityTrend("Scope:1093","",3)

  datax = JSON.parse(data)
  send_event('velocitytrend', points: datax)
end