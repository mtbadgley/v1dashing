require 'json'
require_relative '../lib/v1epicprogress.rb'

SCHEDULER.every '1m', :first_in => 0 do |job|
  v1epicprogress = V1EpicProgress.new
  data = v1epicprogress.GetEpicProgress("Scope:1093","","Feature")
  datax = JSON.parse(data)
  send_event('epicprogress', progress_items: datax)
end