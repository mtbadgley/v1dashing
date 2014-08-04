require 'json'
require_relative '../lib/v1defectpriority.rb'

SCHEDULER.every '1m', :first_in => 0 do |job|
  v1defectpriority = V1DefectPriority.new
  data = v1defectpriority.GetDefectCounts("Scope:1093","")
  datax = JSON.parse(data)
  send_event('defectpriority', { value: datax })
end