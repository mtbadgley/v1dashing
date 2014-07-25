require 'HTTParty'
require 'json'
require 'date'
require 'open-uri'
require 'nokogiri'
require_relative './v1conn.rb'

class V1CycleTime
	$v1conn = V1conn.new

	def GetWorkitemCycleTime(oid,tostatusdate,parentprojectid,fromstatus)
		
		query = "/rest-1.v1/Hist/PrimaryWorkitem?sel=ChangeDate"\
			    "&where=ID=\'#{oid}\';"\
			    "Scope.ParentMeAndUp=\'#{parentprojectid}\';"\
			    "Status.Name=\'#{fromstatus}\'"\
			    "&sort=Number"
		queryuri = $v1conn.baseurl + query

		queryresult = HTTParty.get(URI::encode(queryuri), :basic_auth => $v1conn.auth, :format => 'xml', :output => 'xml')
		xmldoc = Nokogiri::XML(queryresult)

		assets = xmldoc.xpath('//History/Asset')
		if assets.count > 0 
			fromstatusdate = assets[0].xpath('Attribute[@name=\'ChangeDate\']').text[0..9]
			cycledays = DateTime.parse(tostatusdate) - DateTime.parse(fromstatusdate)
		else
			return 0
		end
	end

	def GetRollingCycleTime(numdays,parentprojectid,fromstatus,tostatus)
		
		backdate = Date.today - numdays

		query = "/rest-1.v1/Hist/PrimaryWorkitem?sel=Name,Number,ChangeDate"\
			    "&where=AssetState=\'64\',\'128\';"\
			    "Scope.ParentMeAndUp=\'#{parentprojectid}\';"\
			    "Status.Name=\'#{tostatus}\';"\
			    "ChangeDate>\'#{backdate.to_s}\'"\
			    "&sort=Number,-ChangeDate"
		queryuri = $v1conn.baseurl + query

		queryresult = HTTParty.get(URI::encode(queryuri), :basic_auth => $v1conn.auth, :format => 'xml', :output => 'xml')

		xmldoc = Nokogiri::XML(queryresult)

		cycletime = 0.0
		lastoid = ""

		xmldoc.xpath('//History/Asset').each do |asset|
			oidparts = asset.xpath('@id').to_s.split(':')
			oid = "#{oidparts[0]}:#{oidparts[1]}"
			if oid != lastoid
				changedate = asset.xpath('Attribute[@name=\'ChangeDate\']').text[0..9]
				cycledays = GetWorkitemCycleTime(oid,changedate,parentprojectid,fromstatus).to_f
				if cycledays > 0
					cycletime = (cycletime + cycledays) / 2
				end
				lastoid = oid
			end
		end
		return cycletime
	end
end