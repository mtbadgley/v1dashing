require 'HTTParty'
require 'json'
require 'date'
require_relative './v1conn.rb'

class V1DefectPriority
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


	def GetDefectCounts(parentprojectoid,teamoid)
		
		timeboxoid = GetCurrentSprint(parentprojectoid)

		teamfilter = ''
		if teamoid.length > 0 
			teamfilter = ',"Team=\'' + teamoid + '\'"'
		end

		query = '[{
					"from": "Defect",
					"select": [ "Name" ],
					"filter": [ "AssetState=\'64\'", 
								"Timebox=\'' + timeboxoid + '\'",
								"Scope.ParentMeAndUp=\'' + parentprojectoid + '\'"' + teamfilter + ' ],
					"group":
						    [{
						      "from": "Priority",
						      "select":
						        [
						          "Name"
						        ]
						    }]
				}]'

		queryresult = HTTParty.get($v1queryurl, :body => query, :basic_auth => $v1conn.auth, :output => 'json')
		defects = queryresult[0]

		defectsbyitems = ""

		defects.each do |defect|
			defectsbyoid = defect["_oid"]
			defectsbyname = defect["Name"]
			defectsbychildren = defect["_children"].length
			if defectsbyoid == nil
				defectsbyname = "(none)"
			end
			if defectsbychildren != nil
				defectsbyitem = '{ "label": "' + defectsbyname.to_s + '", "value": ' + defectsbychildren.to_s + ' },'	
				defectsbyitems += defectsbyitem
			end
		end

		if defectsbyitems.length > 0
			defectsbyitems = "[ " + defectsbyitems[0..-2] + " ]"
		else
			defectsbyitems = '[{ "label": "(none)", "value": 0 }]'
		end 
		
		return defectsbyitems
	end
end