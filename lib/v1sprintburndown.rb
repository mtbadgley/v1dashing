require 'HTTParty'
require 'json'
require 'date'
require_relative './v1conn.rb'

class V1SprintBurndown
	attr_accessor :title
	def initialize
		@title = "Sprint Burndown"
	end

	$v1conn = V1conn.new
	$v1queryurl = "#{$v1conn.baseurl}/query.v1"

	def GetTotalOpen(iteration,asofdate,parentprojectoid,teamoid)

		columnkey = "Workitems[Scope.ParentMeAndUp='#{parentprojectoid}'].ToDo.@Sum"
		if teamoid.length > 0
			columnkey = "Workitems[Scope.ParentMeAndUp='#{parentprojectoid}';Team='#{teamoid}'].ToDo.@Sum"
		end

		remainingworkquery = '[{
								"from": "Timebox",
								"select": [ "' + columnkey + '" ],
								"filter": [ "Name=\'' + iteration + '\'" ],
								"asof": "' + asofdate + 'T23:59:59' + '"
								}]'

		result = HTTParty.get($v1queryurl, :body => remainingworkquery, :basic_auth => $v1conn.auth, :output => 'json')
		remainingwork = result[0]
		if remainingwork.count > 0 
			return remainingwork[0][columnkey]
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

	def GetBurndownPoints(parentprojectoid,teamoid)
		query = '[{
					"from": "Timebox",
					"select": [ "BeginDate", "EndDate", "Name" ],
					"filter": [ "AssetState=\'Active\'", 
								"Schedule.ScheduledScopes.ID=\'' + parentprojectoid + '\'" ],
					"sort": "-EndDate"
		}]'

		queryresult = HTTParty.get($v1queryurl, :body => query, :basic_auth => $v1conn.auth, :output => 'json')

		timeboxes = queryresult[0]

		# Use the most recent active timebox
		timboxoid = timeboxes[0]["_oid"]
		timebox = timeboxes[0]["Name"]
		timeboxbegin = timeboxes[0]["BeginDate"][0..9]
		timeboxend = timeboxes[0]["EndDate"][0..9]

		@title = "#{timebox} Burndown"

		dates = GetDatesOfSprint(timeboxbegin,timeboxend)

		points = ""
		i = 1
		dates.each do |dayofwork|
			if Date.parse(dayofwork) <= Date.today
				todo = GetTotalOpen(timebox,dayofwork,parentprojectoid,teamoid)
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
end