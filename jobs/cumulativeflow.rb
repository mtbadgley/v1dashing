require 'json'
require_relative '../lib/v1cumulativeflow.rb'

SCHEDULER.every '20s', first_in: 0 do |job|
	v1cumulativeflow = V1CumulativeFlow.new
	data = v1cumulativeflow.GetCumulativeFlowData("Scope:1093","")
	datax = JSON.parse(data)
	send_event('cumulativeflow', series: datax )
end