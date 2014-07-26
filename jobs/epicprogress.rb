require 'HTTParty'
require 'json'
require 'date'

$v1user = "admin"
$v1pass = "admin"
$auth = {:username => $v1user, :password => $v1pass}
$v1queryurl = "http://win8/VersionOne/query.v1"

def GetEpicProgress(parentprojectoid,teamoid,epictypename)

	totalcolumnkey = "SubsAndDown:PrimaryWorkitem[AssetState=\'64\',\'128\'].Estimate.@Sum"
	closedcolumnkey = "SubsAndDown:PrimaryWorkitem[AssetState=\'128\'].Estimate.@Sum"
	if teamoid.length > 0
		totalcolumnkey = "SubsAndDown:PrimaryWorkitem[AssetState=\'64\',\'128\';Team=\'#{teamoid}\'].Estimate.@Sum"
		closedcolumnkey = "SubsAndDown:PrimaryWorkitem[AssetState=\'128\';Team=\'#{teamoid}\'].Estimate.@Sum"
	end	
	query = '[{
				"from": "Epic",
				"select": [ "Name","' + totalcolumnkey + '", "' + closedcolumnkey + '" ],
				"filter": [ "AssetState=\'64\',\'128\'", 
							"Scope.ParentMeAndUp=\'' + parentprojectoid + '\'",
							"Category.Name=\'' +  epictypename + '\'" ],
				"sort": "Order"
	}]'

	queryresult = HTTParty.get($v1queryurl, :body => query, :basic_auth => $auth, :output => 'json')
	epics = queryresult[0]

	progressitems = ""

	epics.each do |epic|
		epicoid = epic["_oid"]
		epicname = epic["Name"]
		totalestimate = epic[totalcolumnkey].to_f
		closedestimate = epic[closedcolumnkey].to_f
		if totalestimate > 0 then
			perccomplete = ((closedestimate / totalestimate) * 100).round(1)
		else
			perccomplete = 0.0
		end
		progressitem = '{ "name": "' + epicname + '", "progress": ' + perccomplete.to_s + ' },'	
		progressitems += progressitem
	end


	if progressitems.length > 0
		progressitems = "[ " + progressitems[0..-2] + " ]"
	end 

#	puts progressitems
	
	return progressitems
end

SCHEDULER.every '1m', :first_in => 0 do |job|
  data = GetEpicProgress("Scope:1093","","Feature")

  datax = JSON.parse(data)
  send_event('epicprogress', progress_items: datax)
end