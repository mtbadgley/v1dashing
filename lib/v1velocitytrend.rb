require 'HTTParty'
require 'json'
require 'date'
require_relative './v1conn.rb'

class V1VelocityTrend
	$v1conn = V1conn.new
	$v1queryurl = "#{$v1conn.baseurl}/query.v1"

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

		result = HTTParty.get($v1queryurl, :body => velocitytrendquery, :basic_auth => $v1conn.auth, :output => 'json')
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
end