require 'HTTParty'
require 'json'
require 'date'
require_relative './v1conn.rb'

class V1RemainingDays
	def initialize
		@moreinfo = "Days Remaining"
		@title = ""
	end

	attr_accessor :moreinfo
	attr_accessor :title

	$v1conn = V1conn.new
	$v1queryurl = "#{$v1conn.baseurl}/query.v1"

	def GetRemainingDays(parentprojectoid)
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
		timeboxend = timeboxes[0]["EndDate"][0..9]

		@title = "#{timebox}"

		remainingdays = 0
		if Date.today <= Date.parse(timeboxend)
			remainingdays = (Date.parse(timeboxend) - Date.today).to_i
		end
		
		return remainingdays
	end
end