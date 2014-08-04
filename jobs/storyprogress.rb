require 'json'
require_relative '../lib/v1storyprogress.rb'

SCHEDULER.every '1m', :first_in => 0 do |job|
  v1storyprogress = V1StoryProgress.new
  data = v1storyprogress.GetStoryProgress("Scope:1093","")
  datax = JSON.parse(data)
  send_event('storyprogress', progress_items: datax)
end