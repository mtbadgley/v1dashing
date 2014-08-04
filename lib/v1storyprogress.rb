require 'HTTParty'
require 'json'
require 'date'
require_relative './v1conn.rb'

class V1StoryProgress
	$v1conn = V1conn.new
	$v1queryurl = "#{$v1conn.baseurl}/query.v1"

	def GetCurrentSprint(parentprojectoid)
		query = '[{
				"from": "Timebox",
				"select": [ "Name" ],
				"filter": [ "AssetState=\'Active\'", 
							"Schedule.ScheduledScopes.ID=\'' + parentprojectoid + '\'" ],
				"sort": "-EndDate"
				}]'

		queryresult = HTTParty.get($v1queryurl, :body => query, :basic_auth => $v1conn.auth, :output => 'json')

		timeboxes = queryresult[0]

		# Use the most recent active timebox
		timeboxoid = timeboxes[0]["_oid"]
		return timeboxoid
	end


	def GetStoryProgress(parentprojectoid,teamoid)
		
		timeboxoid = GetCurrentSprint(parentprojectoid)

		columntodokey = "Children[AssetState=\'64\'].ToDo.@Sum"
		columndetailestimatekey = "Children[AssetState=\'64\',\'128\'].DetailEstimate.@Sum"

		teamfilter = ''
		if teamoid.length > 0 
			teamfilter = ',"Team=\'' + teamoid + '\'"'
		end

		query = '[{
					"from": "PrimaryWorkitem",
					"select": [ "Name",
							    "' + columntodokey + '", 
							    "' + columndetailestimatekey + '",
							    "AssetState" ],
					"filter": [ "AssetState=\'64\',\'128\'", 
								"AssetType=\'Story\'",
								"Timebox=\'' + timeboxoid + '\'",
								"Scope.ParentMeAndUp=\'' + parentprojectoid + '\'"' + teamfilter + ' ],
					"sort": "Order"
				}]'
				
		queryresult = HTTParty.get($v1queryurl, :body => query, :basic_auth => $v1conn.auth, :output => 'json')
		stories = queryresult[0]

		progressitems = ""

		stories.each do |story|
			storyoid = story["_oid"]
			storyname = story["Name"]
			storyassetstate = story["AssetState"]
			totaltodo = story[columntodokey].to_f
			totaldetailestimate = story[columndetailestimatekey].to_f
			if totaldetailestimate < totaltodo
				totaldetailestimate = totaltodo
			end
			if totaldetailestimate > 0
				perccomplete = (((totaldetailestimate - totaltodo) / totaldetailestimate) * 100).round(1)
			else
				perccomplete = 0.0
			end
			if storyassetstate == '128'
				perccomplete = 100.0
			end
			progressitem = '{ "name": "' + storyname + '", "progress": ' + perccomplete.to_s + ' },'	
			progressitems += progressitem
		end


		if progressitems.length > 0
			progressitems = "[ " + progressitems[0..-2] + " ]"
		end 
		
		return progressitems
	end
end
